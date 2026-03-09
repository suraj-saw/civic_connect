import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/report_issue_controller.dart';

class DescriptionField extends GetView<ReportIssueController> {
  const DescriptionField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.descriptionTextController,
          onChanged: (value) {
            controller.description.value = value;
            controller.isFormDirty.value = true;
          },
          maxLength: 500,
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Provide detailed information about the issue...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
