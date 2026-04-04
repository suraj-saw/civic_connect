import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/constants/mapbox_constants.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static final _initialDelhi = Point(coordinates: Position(77.2090, 28.6139));
  static final _publicToken = MapboxConstants.publicToken;
  static const _trafficStyleUri = 'mapbox://styles/mapbox/navigation-day-v1';

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

  StreamSubscription<geo.Position>? _headingSub;
  double? _lastAppliedBearing;
  DateTime? _lastBearingUpdateAt;

  @override
  void initState() {
    super.initState();
    _selectedStyle = _primaryTypeOptions['Default']!;
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
                    _MapTypeGrid(
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
                    _MapDetailsGrid(
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
      return const _MissingTokenView();
    }

    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('citizen_mapbox_map'),
          styleUri: _resolvedStyleUri,
          cameraOptions: CameraOptions(
            center: _initialDelhi,
            zoom: 13.2,
            pitch: 0,
          ),
          onMapCreated: (mapboxMap) async {
            _mapboxMap = mapboxMap;
            await mapboxMap.compass.updateSettings(
              CompassSettings(enabled: true, fadeWhenFacingNorth: false),
            );
            await _enableLocationIndicator();
            await _goToCurrentLocation(silent: true);
          },
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _MapControlStack(
            topButton: _MapCircleButton(
              icon: Icons.layers_outlined,
              tooltip: 'Map type',
              onTap: _openMapTypeSheet,
            ),
            bottomButton: _MapCircleButton(
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
          child: _MapCircleButton(
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
    super.dispose();
  }
}

class _MapControlStack extends StatelessWidget {
  final Widget topButton;
  final Widget bottomButton;

  const _MapControlStack({required this.topButton, required this.bottomButton});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [topButton, const SizedBox(height: 10), bottomButton],
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}

class _MapTypeTile extends StatelessWidget {
  final String title;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _MapTypeTile({
    required this.title,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Container(
              width: 86,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors:
                      selected
                          ? [const Color(0xFF81D4FA), const Color(0xFFB2DFDB)]
                          : [const Color(0xFFCFD8DC), const Color(0xFFECEFF1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color:
                      selected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.35),
                  width: selected ? 2.2 : 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTypeGrid extends StatelessWidget {
  final Map<String, String> options;
  final String selectedStyle;
  final ValueChanged<String> onSelect;

  const _MapTypeGrid({
    required this.options,
    required this.selectedStyle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();
    return Row(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          Expanded(
            child: _MapTypeTile(
              title: entries[index].key,
              selected: selectedStyle == entries[index].value,
              colorScheme: Theme.of(context).colorScheme,
              onTap: () => onSelect(entries[index].value),
            ),
          ),
          if (index < entries.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _MapDetailsGrid extends StatelessWidget {
  final bool showPublicTransport;
  final bool showTraffic;
  final VoidCallback onTogglePublicTransport;
  final VoidCallback onToggleTraffic;

  const _MapDetailsGrid({
    required this.showPublicTransport,
    required this.showTraffic,
    required this.onTogglePublicTransport,
    required this.onToggleTraffic,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _MapDetailTile(
          title: 'Public\ntransport',
          selected: showPublicTransport,
          icon: Icons.directions_transit_rounded,
          colorScheme: cs,
          onTap: onTogglePublicTransport,
        ),
        _MapDetailTile(
          title: 'Traffic',
          selected: showTraffic,
          icon: Icons.traffic_rounded,
          colorScheme: cs,
          onTap: onToggleTraffic,
        ),
      ],
    );
  }
}

class _MapDetailTile extends StatelessWidget {
  final String title;
  final bool selected;
  final IconData icon;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _MapDetailTile({
    required this.title,
    required this.selected,
    required this.icon,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 104,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color:
                    selected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color:
                      selected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.35),
                  width: selected ? 2.2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: selected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingTokenView extends StatelessWidget {
  const _MissingTokenView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.error.withValues(alpha: 0.35)),
          ),
          child: const Text(
            'Mapbox token is missing. Add your public token to the .env file in the project root.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

