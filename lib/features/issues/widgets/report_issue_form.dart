import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/constants/mapbox_constants.dart';
import '../controllers/report_issue_controller.dart';
import 'category_dropdown.dart';
import 'description_field.dart';
import 'package:flutter/foundation.dart';

class ReportIssueForm extends GetView<ReportIssueController> {
  const ReportIssueForm({super.key});

  static final _defaultPreviewCenter =
  Point(coordinates: Position(77.2090, 28.6139));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _locationPreview(context, cs),
        const SizedBox(height: 16),
        const DescriptionField(),
        const SizedBox(height: 20),
        const CategoryDropdown(),
      ],
    );
  }

  Widget _locationPreview(BuildContext context, ColorScheme cs) {
    return Obx(() {
      final location = controller.issueLocation.value;
      final hasLocation = location != null;
      final latitude = (location?['latitude'] as num?)?.toDouble();
      final longitude = (location?['longitude'] as num?)?.toDouble();
      final previewCenter =
      latitude != null && longitude != null
          ? Point(coordinates: Position(longitude, latitude))
          : _defaultPreviewCenter;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasLocation
              ? cs.primaryContainer.withValues(alpha: 0.35)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasLocation
                ? cs.primary.withValues(alpha: 0.3)
                : cs.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasLocation
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  color: hasLocation ? cs.primary : cs.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issue Location',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: cs.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasLocation
                            ? 'Lat: ${latitude?.toStringAsFixed(5)}, Lng: ${longitude?.toStringAsFixed(5)}'
                            : 'Fetching GPS location...',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                      if (hasLocation &&
                          latitude != null &&
                          longitude != null) ...[
                        const SizedBox(height: 4),
                        _ResolvedAddressText(
                          latitude: latitude,
                          longitude: longitude,
                          textStyle: GoogleFonts.inter(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasLocation)
                  Icon(Icons.check_circle_rounded,
                      color: cs.primary, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            // Map preview — hidden on web since Mapbox doesn't support web
            if (!kIsWeb)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (MapboxConstants.publicToken.isNotEmpty)
                        AbsorbPointer(
                          child: MapWidget(
                            key: ValueKey(
                              'issue_location_preview_${latitude ?? 0}_${longitude ?? 0}',
                            ),
                            styleUri: MapboxStyles.STANDARD,
                            cameraOptions: CameraOptions(
                              center: previewCenter,
                              zoom: hasLocation ? 16.5 : 3,
                              pitch: 0,
                            ),
                          ),
                        )
                      else
                        Container(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                          alignment: Alignment.center,
                          child: Text(
                            'Map preview unavailable',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: cs.onSurfaceVariant),
                          ),
                        ),
                      if (hasLocation)
                        Center(
                          child: Icon(Icons.location_pin,
                              size: 40, color: cs.error),
                        ),
                      if (!hasLocation)
                        Container(
                          color: Colors.black.withValues(alpha: 0.08),
                          alignment: Alignment.center,
                          child: Text(
                            'Waiting for GPS fix...',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
            // Web: show a simple location info card instead of map
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hasLocation
                      ? cs.primaryContainer.withValues(alpha: 0.3)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasLocation
                        ? cs.primary.withValues(alpha: 0.25)
                        : cs.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    hasLocation ? Icons.check_circle_outline : Icons.location_searching_rounded,
                    color: hasLocation ? cs.primary : cs.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLocation ? 'Location captured' : 'Requesting browser location...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasLocation ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                        if (hasLocation) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Lat: ${latitude?.toStringAsFixed(5)}, Lng: ${longitude?.toStringAsFixed(5)}',
                            style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Map preview is not available on web.',
                            style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
            if (hasLocation && !kIsWeb) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: latitude == null || longitude == null
                      ? null
                      : () => _openLocationAdjuster(
                      context, latitude, longitude),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Adjust location'),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _openLocationAdjuster(
      BuildContext context,
      double initialLatitude,
      double initialLongitude,
      ) async {
    final currentLocation = controller.issueLocation.value;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => _LocationAdjusterPage(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          currentLocation: currentLocation,
          onUseLocation: (latitude, longitude) {
            controller.updateIssueLocation(
              latitude: latitude,
              longitude: longitude,
              accuracy: (currentLocation?['accuracy'] as num?)?.toDouble(),
              source: 'manual_adjusted',
            );
          },
        ),
      ),
    );
  }
}

class _LocationAdjusterPage extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final Map<String, dynamic>? currentLocation;
  final void Function(double latitude, double longitude) onUseLocation;

  const _LocationAdjusterPage({
    required this.initialLatitude,
    required this.initialLongitude,
    required this.currentLocation,
    required this.onUseLocation,
  });

  @override
  State<_LocationAdjusterPage> createState() => _LocationAdjusterPageState();
}

class _LocationAdjusterPageState extends State<_LocationAdjusterPage> {
  MapboxMap? _mapboxMap;
  bool _mapReady = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initialCenter = Point(
      coordinates: Position(widget.initialLongitude, widget.initialLatitude),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Adjust issue location'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Move the map until the center pin matches the correct spot, then save it.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (MapboxConstants.publicToken.isNotEmpty)
                      MapWidget(
                        key: const ValueKey('issue_location_adjuster_map'),
                        styleUri: MapboxStyles.STANDARD,
                        cameraOptions: CameraOptions(
                          center: initialCenter,
                          zoom: 16.5,
                          pitch: 0,
                        ),
                        onMapCreated: (map) async {
                          _mapboxMap = map;
                          await map.compass.updateSettings(
                            CompassSettings(
                              enabled: false,
                              fadeWhenFacingNorth: false,
                            ),
                          );
                          if (mounted) {
                            setState(() => _mapReady = true);
                          }
                        },
                      )
                    else
                      Container(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                        alignment: Alignment.center,
                        child: Text(
                          'Map preview unavailable',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    IgnorePointer(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_pin, size: 44, color: cs.error),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surface.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: cs.outline.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                _mapReady
                                    ? 'Move the map under this pin'
                                    : 'Loading map...',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.currentLocation != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current: ${((widget.currentLocation?['latitude'] as num?)?.toDouble() ?? 0).toStringAsFixed(5)}, ${((widget.currentLocation?['longitude'] as num?)?.toDouble() ?? 0).toStringAsFixed(5)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ResolvedAddressText(
                    latitude:
                    ((widget.currentLocation?['latitude'] as num?)
                        ?.toDouble() ??
                        0),
                    longitude:
                    ((widget.currentLocation?['longitude'] as num?)
                        ?.toDouble() ??
                        0),
                    textStyle: GoogleFonts.inter(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                    _mapboxMap == null
                        ? null
                        : () async {
                      final camera = await _mapboxMap!.getCameraState();
                      widget.onUseLocation(
                        camera.center.coordinates.lat.toDouble(),
                        camera.center.coordinates.lng.toDouble(),
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Use this location'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolvedAddressText extends StatefulWidget {
  final double latitude;
  final double longitude;
  final TextStyle textStyle;

  const _ResolvedAddressText({
    required this.latitude,
    required this.longitude,
    required this.textStyle,
  });

  @override
  State<_ResolvedAddressText> createState() => _ResolvedAddressTextState();
}

class _ResolvedAddressTextState extends State<_ResolvedAddressText> {
  static final Map<String, String> _cache = {};
  String? _address;
  bool _loading = false;

  String get _cacheKey =>
      '${widget.latitude.toStringAsFixed(5)},${widget.longitude.toStringAsFixed(5)}';

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void didUpdateWidget(covariant _ResolvedAddressText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _loadAddress();
    }
  }

  Future<void> _loadAddress() async {
    final cached = _cache[_cacheKey];
    if (cached != null) {
      if (mounted) {
        setState(() {
          _address = cached;
          _loading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final languageCode =
      locale.languageCode.isEmpty ? 'en' : locale.languageCode;
      String resolved = 'Address unavailable';

      if (MapboxConstants.publicToken.isNotEmpty) {
        final uri = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/'
              '${widget.longitude},${widget.latitude}.json'
              '?limit=5'
              '&types=address,poi,neighborhood,locality,place'
              '&language=$languageCode'
              '&access_token=${MapboxConstants.publicToken}',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final features = (data['features'] as List?) ?? const [];
          resolved = _resolveBestAddress(features);
          if (resolved == 'Address unavailable') {
            resolved = await _fallbackReverseGeocode(languageCode);
          }
        }
      }

      if (resolved == 'Address unavailable') {
        resolved = await _fallbackOpenStreetMap(languageCode);
      }

      _cache[_cacheKey] = resolved;
      if (mounted) {
        setState(() {
          _address = resolved;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = 'Address unavailable';
          _loading = false;
        });
      }
    }
  }

  Future<String> _fallbackReverseGeocode(String languageCode) async {
    try {
      final uri = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/'
            '${widget.longitude},${widget.latitude}.json'
            '?limit=1'
            '&language=$languageCode'
            '&access_token=${MapboxConstants.publicToken}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return 'Address unavailable';
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (data['features'] as List?) ?? const [];
      if (features.isEmpty) return 'Address unavailable';
      final feature = (features.first as Map).cast<String, dynamic>();
      final placeName = (feature['place_name'] as String?)?.trim();
      if (placeName == null || placeName.isEmpty) return 'Address unavailable';
      return placeName;
    } catch (_) {
      return 'Address unavailable';
    }
  }

  Future<String> _fallbackOpenStreetMap(String languageCode) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?format=jsonv2'
            '&lat=${widget.latitude}'
            '&lon=${widget.longitude}'
            '&accept-language=$languageCode',
      );
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'CivicConnect/1.0'},
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return 'Address unavailable';

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final displayName = (data['display_name'] as String?)?.trim();
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }

      final address = (data['address'] as Map?)?.cast<String, dynamic>();
      if (address != null && address.isNotEmpty) {
        final road = (address['road'] ?? address['pedestrian'] ?? '').toString();
        final number = (address['house_number'] ?? '').toString();
        final suburb = (address['suburb'] ?? address['neighbourhood'] ?? '').toString();
        final city = (address['city'] ?? address['town'] ?? address['village'] ?? '').toString();
        final parts = <String>[
          if ('$number $road'.trim().isNotEmpty) '$number $road'.trim(),
          if (suburb.trim().isNotEmpty) suburb.trim(),
          if (city.trim().isNotEmpty) city.trim(),
        ];
        if (parts.isNotEmpty) return parts.join(', ');
      }

      return 'Address unavailable';
    } catch (_) {
      return 'Address unavailable';
    }
  }

  String _resolveBestAddress(List features) {
    if (features.isEmpty) return 'Address unavailable';

    Map<String, dynamic>? preferred;
    const priority = ['address', 'poi', 'neighborhood', 'locality', 'place'];
    for (final type in priority) {
      for (final raw in features) {
        final feature = (raw as Map).cast<String, dynamic>();
        final placeTypes =
            (feature['place_type'] as List?)?.map((e) => '$e').toList() ??
                const <String>[];
        if (placeTypes.contains(type)) {
          preferred = feature;
          break;
        }
      }
      if (preferred != null) break;
    }

    preferred ??= (features.first as Map).cast<String, dynamic>();

    final text = (preferred['text'] as String?)?.trim();
    final number = (preferred['address'] as String?)?.trim();
    final placeName = (preferred['place_name'] as String?)?.trim();
    final primary =
    number != null && number.isNotEmpty && text != null && text.isNotEmpty
        ? '$number $text'
        : (text?.isNotEmpty == true ? text! : (placeName ?? ''));

    if (placeName != null && placeName.isNotEmpty) {
      if (primary.isEmpty) return placeName;
      if (!placeName.toLowerCase().startsWith(primary.toLowerCase())) {
        return '$primary, $placeName';
      }
      return placeName;
    }

    return primary.isEmpty ? 'Address unavailable' : primary;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _loading ? 'Resolving address...' : (_address ?? 'Address unavailable'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: widget.textStyle,
    );
  }
}
