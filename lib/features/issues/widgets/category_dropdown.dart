import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/report_issue_controller.dart';

class CategoryDropdown extends GetView<ReportIssueController> {
  const CategoryDropdown({Key? key}) : super(key: key);

  static const List<Map<String, String>> categories = [
    {'value': 'road_damage', 'label': 'Road Damage'},
    {'value': 'street_light', 'label': 'Street Light'},
    {'value': 'water_supply', 'label': 'Water Supply'},
    {'value': 'sanitation', 'label': 'Sanitation'},
    {'value': 'public_safety', 'label': 'Public Safety'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          return DropdownButton<String>(
            value: controller.selectedCategoryId.value,
            isExpanded: true,
            hint: const Text('Select a category'),
            onChanged: (value) {
              controller.selectedCategoryId.value = value;
              controller.isFormDirty.value = true;
            },
            items: categories
                .map((cat) => DropdownMenuItem(
              value: cat['value'],
              child: Text(cat['label']!),
            ))
                .toList(),
          );
        }),
      ],
    );
  }
}