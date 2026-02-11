import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/report_issue_controller.dart';
import 'category_dropdown.dart';
import 'description_field.dart';

class ReportIssueForm extends GetView<ReportIssueController> {
  const ReportIssueForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationPreview(context),
        const SizedBox(height: 16),
        const DescriptionField(),
        const SizedBox(height: 24),
        const CategoryDropdown(),
      ],
    );
  }

  Widget _buildLocationPreview(BuildContext context) {
    return Obx(() {
      final location = controller.issueLocation.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Issue Location Preview',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            if (location == null)
              const Text('Fetching location or waiting for permission...')
            else
              Text(
                'Lat: ${location['latitude']?.toStringAsFixed(6)} | '
                    'Lng: ${location['longitude']?.toStringAsFixed(6)} '
                    '(±${(location['accuracy'] ?? 0).toStringAsFixed(1)}m)',
              ),
          ],
        ),
      );
    });
  }
}
