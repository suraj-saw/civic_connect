import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/report_issue_controller.dart';
import 'category_dropdown.dart';
import 'description_field.dart';

class ReportIssueForm extends GetView<ReportIssueController> {
  const ReportIssueForm({Key? key}) : super(key: key);

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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasLocation ? cs.primaryContainer.withOpacity(0.35) : cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasLocation ? cs.primary.withOpacity(0.3) : cs.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(
              hasLocation ? Icons.my_location_rounded : Icons.location_searching_rounded,
              color: hasLocation ? cs.primary : cs.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Issue Location', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(
                    hasLocation
                        ? 'Lat: ${location['latitude']?.toStringAsFixed(5)}, Lng: ${location['longitude']?.toStringAsFixed(5)}'
                        : 'Fetching GPS location...',
                    style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (hasLocation) Icon(Icons.check_circle_rounded, color: cs.primary, size: 18),
          ],
        ),
      );
    });
  }
}
