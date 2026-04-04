import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/constants/mapbox_constants.dart';
import '../controllers/report_issue_controller.dart';
import 'category_dropdown.dart';
import 'description_field.dart';

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
          color:
              hasLocation
                  ? cs.primaryContainer.withOpacity(0.35)
                  : cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                hasLocation
                    ? cs.primary.withOpacity(0.3)
                    : cs.outline.withOpacity(0.2),
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
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasLocation
                            ? 'Lat: ${latitude?.toStringAsFixed(5)}, Lng: ${longitude?.toStringAsFixed(5)}'
                            : 'Fetching GPS location...',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasLocation)
                  Icon(Icons.check_circle_rounded, color: cs.primary, size: 18),
              ],
            ),
            const SizedBox(height: 12),
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
                        color: cs.surfaceContainerHighest.withOpacity(0.7),
                        alignment: Alignment.center,
                        child: Text(
                          'Map preview unavailable',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (hasLocation)
                      Center(
                        child: Icon(
                          Icons.location_pin,
                          size: 40,
                          color: cs.error,
                        ),
                      ),
                    if (!hasLocation)
                      Container(
                        color: Colors.black.withOpacity(0.08),
                        alignment: Alignment.center,
                        child: Text(
                          'Waiting for GPS fix...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (hasLocation) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      latitude == null || longitude == null
                          ? null
                          : () => _openLocationAdjuster(
                            context,
                            latitude,
                            longitude,
                          ),
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return _LocationAdjusterSheet(
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
        );
      },
    );
  }
}

class _LocationAdjusterSheet extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final Map<String, dynamic>? currentLocation;
  final void Function(double latitude, double longitude) onUseLocation;

  const _LocationAdjusterSheet({
    required this.initialLatitude,
    required this.initialLongitude,
    required this.currentLocation,
    required this.onUseLocation,
  });

  @override
  State<_LocationAdjusterSheet> createState() => _LocationAdjusterSheetState();
}

class _LocationAdjusterSheetState extends State<_LocationAdjusterSheet> {
  MapboxMap? _mapboxMap;
  bool _mapReady = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initialCenter = Point(
      coordinates: Position(widget.initialLongitude, widget.initialLatitude),
    );

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adjust issue location',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
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
                        color: cs.surfaceContainerHighest.withOpacity(0.7),
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
                                color: cs.surface.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: cs.outline.withOpacity(0.15),
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
              Text(
                'Current: ${((widget.currentLocation?['latitude'] as num?)?.toDouble() ?? 0).toStringAsFixed(5)}, ${((widget.currentLocation?['longitude'] as num?)?.toDouble() ?? 0).toStringAsFixed(5)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
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
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
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
