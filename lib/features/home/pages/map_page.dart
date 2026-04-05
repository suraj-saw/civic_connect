import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/constants/mapbox_constants.dart';
import '../../../core/utils/location_storage_service.dart';
import '../../../data/services/firestore_service.dart';
import '../utils/map_markers_manager.dart';
import '../utils/map_issue_bottom_sheet.dart';
import '../widgets/map_controls.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static final _initialDelhi = Point(coordinates: Position(77.2090, 28.6139));
  static final _publicToken = MapboxConstants.publicToken;
  static const _trafficStyleUri = 'mapbox://styles/mapbox/navigation-day-v1';
  static const _startupCurrentLocationDelay = Duration(milliseconds: 900);

  final Map<String, String> _primaryTypeOptions = const {
    'Default': MapboxStyles.STANDARD,
    'Satellite': MapboxStyles.SATELLITE,
    'Terrain': MapboxStyles.OUTDOORS,
  };

  MapboxMap? _mapboxMap;
  late String _selectedStyle;
  bool _isLocating = false;
  bool _showPublicTransport = true;
  bool _showTraffic = false;
  bool _show3D = false;
  late Point _initialLocation;
  bool _hasRestoredLastLocation = false;

  StreamSubscription<geo.Position>? _headingSub;
  double? _lastAppliedBearing;
  DateTime? _lastBearingUpdateAt;

  final _firestoreService = FirestoreService();
  StreamSubscription<QuerySnapshot>? _issuesStreamSub;
  MapMarkersManager? _markersManager;

  @override
  void initState() {
    super.initState();
    _selectedStyle = _primaryTypeOptions['Default']!;
    _initialLocation = _initialDelhi;
    _restoreInitialLocation();
  }

  void _setupIssuesListener() {
    if (_markersManager == null) return;
    _issuesStreamSub = _firestoreService.getVisibleIssuesStream().listen(
      (snapshot) {
        if (mounted && _markersManager != null) {
          _markersManager!.updateMarkers(snapshot.docs);
        }
      },
      onError: (e) {
        debugPrint('[Issues Stream Error]: $e');
      },
    );
  }

  Future<void> _initializeMarkersManager() async {
    if (_mapboxMap != null && _markersManager == null) {
      _markersManager = MapMarkersManager(
        mapboxMap: _mapboxMap,
        onAnnotationTap: (issues) {
          IssueDetailBottomSheet.showGrouped(context, issues);
        },
      );
      // Setup listener after manager is initialized
      _setupIssuesListener();
      // Load initial issues
      try {
        final snapshot = await _firestoreService.getVisibleIssuesStream().first;
        if (mounted) {
          await _markersManager!.updateMarkers(snapshot.docs);
        }
      } catch (e) {
        debugPrint('[Initialize Markers Error]: $e');
      }
    }
  }

  Future<void> _restoreInitialLocation() async {
    final lastLocation = await LocationStorageService.getLastLocation();
    if (!mounted) return;

    setState(() {
      if (lastLocation != null) {
        _initialLocation = Point(
          coordinates: Position(lastLocation.longitude, lastLocation.latitude),
        );
      }
      _hasRestoredLastLocation = true;
    });
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'Restoring your last map location...',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startStartupLocationSync() async {
    await Future<void>.delayed(_startupCurrentLocationDelay);
    if (!mounted) return;
    await _goToCurrentLocation(silent: true);
  }

  String get _resolvedStyleUri {
    if (_showTraffic && _selectedStyle != MapboxStyles.SATELLITE) {
      return _trafficStyleUri;
    }
    return _selectedStyle;
  }

  Future<void> _changeStyle(String styleUri) async {
    if (_selectedStyle == styleUri) return;
    setState(() => _selectedStyle = styleUri);
    await _applyResolvedStyle();
  }

  Future<void> _applyResolvedStyle() async {
    final map = _mapboxMap;
    if (map == null) return;

    final camera = await map.getCameraState();
    await map.loadStyleURI(_resolvedStyleUri);
    await _markersManager?.onStyleReloaded();
    await _enableLocationIndicator();
    await map.easeTo(
      CameraOptions(
        center: camera.center,
        zoom: camera.zoom,
        bearing: camera.bearing,
        pitch: _show3D ? 45 : 0,
      ),
      MapAnimationOptions(duration: 420),
    );
  }

  Future<bool> _ensureLocationPermission({
    required bool requestIfNeeded,
  }) async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied && requestIfNeeded) {
      permission = await geo.Geolocator.requestPermission();
    }

    return permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse;
  }

  Future<void> _enableLocationIndicator() async {
    final map = _mapboxMap;
    if (map == null) return;

    final hasPermission = await _ensureLocationPermission(
      requestIfNeeded: false,
    );
    if (!hasPermission) return;

    await map.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
    );
  }

  double _headingDelta(double from, double to) {
    final raw = (to - from).abs() % 360;
    return raw > 180 ? 360 - raw : raw;
  }

  Future<void> _startHeadingFollowIfNeeded() async {
    await _headingSub?.cancel();
    _headingSub = null;

    if (!_show3D) return;
    final hasPermission = await _ensureLocationPermission(
      requestIfNeeded: false,
    );
    if (!hasPermission) return;

    _headingSub = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((pos) async {
      final map = _mapboxMap;
      if (map == null || !_show3D) return;
      if (pos.heading.isNaN || pos.heading < 0) return;

      final now = DateTime.now();
      final nextBearing = pos.heading.toDouble();

      // Smooth heading updates: ignore tiny changes and rate-limit updates.
      if (_lastAppliedBearing != null) {
        final delta = _headingDelta(_lastAppliedBearing!, nextBearing);
        if (delta < 7) return;
      }
      if (_lastBearingUpdateAt != null &&
          now.difference(_lastBearingUpdateAt!) <
              const Duration(milliseconds: 320)) {
        return;
      }

      _lastAppliedBearing = nextBearing;
      _lastBearingUpdateAt = now;
      await map.setCamera(CameraOptions(bearing: nextBearing, pitch: 45));
    });
  }

  Future<void> _goToCurrentLocation({bool silent = false}) async {
    if (_isLocating) return;
    if (!silent) setState(() => _isLocating = true);

    try {
      final hasPermission = await _ensureLocationPermission(
        requestIfNeeded: true,
      );
      if (!hasPermission) {
        final permission = await geo.Geolocator.checkPermission();
        if (permission == geo.LocationPermission.deniedForever) {
          await geo.Geolocator.openAppSettings();
        }
        if (mounted && !silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enable location permission in app settings.'),
            ),
          );
        }
        return;
      }

      geo.Position? pos = await geo.Geolocator.getLastKnownPosition();
      try {
        pos = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } on TimeoutException {
        // Fall back to last known when live fix is slow.
      }

      if (pos == null) {
        if (mounted && !silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Current location unavailable.')),
          );
        }
        return;
      }

      final map = _mapboxMap;
      if (map != null) {
        await _enableLocationIndicator();
        final target = Point(
          coordinates: Position(pos.longitude, pos.latitude),
        );
        await map.easeTo(
          CameraOptions(center: target, zoom: 16.5, pitch: _show3D ? 45 : 0),
          MapAnimationOptions(duration: 1000),
        );
        // Save the location for future app launches
        await LocationStorageService.saveLastLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        await _startHeadingFollowIfNeeded();
      }
    } catch (_) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch current location.')),
        );
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _toggle3D() async {
    setState(() => _show3D = !_show3D);
    if (!_show3D) {
      _lastAppliedBearing = null;
      _lastBearingUpdateAt = null;
    }
    await _applyResolvedStyle();
    await _startHeadingFollowIfNeeded();
  }

  Future<void> _openMapTypeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Map type',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how the map looks and what extra details are visible.',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    MapTypeGrid(
                      options: _primaryTypeOptions,
                      selectedStyle: _selectedStyle,
                      onSelect: (style) async {
                        await _changeStyle(style);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    const Text(
                      'Map details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    MapDetailsGrid(
                      showPublicTransport: _showPublicTransport,
                      showTraffic: _showTraffic,
                      onTogglePublicTransport: () {
                        setState(
                          () => _showPublicTransport = !_showPublicTransport,
                        );
                        setModalState(() {});
                      },
                      onToggleTraffic: () async {
                        setState(() => _showTraffic = !_showTraffic);
                        setModalState(() {});
                        await _applyResolvedStyle();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_publicToken.isEmpty) {
      return const MissingTokenView();
    }

    if (!_hasRestoredLastLocation) {
      return _buildLoadingPlaceholder(context);
    }

    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('citizen_mapbox_map'),
          styleUri: _resolvedStyleUri,
          cameraOptions: CameraOptions(
            center: _initialLocation,
            zoom: 13.2,
            pitch: 0,
          ),
          onMapCreated: (mapboxMap) async {
            _mapboxMap = mapboxMap;
            await mapboxMap.compass.updateSettings(
              CompassSettings(enabled: true, fadeWhenFacingNorth: false),
            );
            await _enableLocationIndicator();
            await _initializeMarkersManager();
            await _startStartupLocationSync();
          },
        ),
        Positioned(
          top: 12,
          right: 12,
          child: MapControlStack(
            topButton: MapCircleButton(
              icon: Icons.layers_outlined,
              tooltip: 'Map type',
              onTap: _openMapTypeSheet,
            ),
            bottomButton: MapCircleButton(
              icon:
                  _show3D ? Icons.explore_off_outlined : Icons.explore_outlined,
              tooltip: '3D view',
              onTap: _toggle3D,
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 24,
          child: MapCircleButton(
            icon: _isLocating ? Icons.gps_not_fixed_rounded : Icons.my_location,
            tooltip: 'Current location',
            onTap: _goToCurrentLocation,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _headingSub?.cancel();
    _issuesStreamSub?.cancel();
    _markersManager?.clearAll();
    super.dispose();
  }
}
