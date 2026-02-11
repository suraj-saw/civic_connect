import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/issue_category_controller.dart';
import '../controllers/report_issue_controller.dart';

class CategoryDropdown extends GetView<ReportIssueController> {
  const CategoryDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<IssueCategoryController>();

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
          if (categoryController.isLoading.value) {
            return const LinearProgressIndicator();
          }

          final categories = categoryController.categories;

          if (categories.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(10),
                color: Colors.orange.shade50,
              ),
              child: const Text(
                'No active issue categories found. Please try again later.',
              ),
            );
          }

          return DropdownButtonFormField<String>(
            value: controller.selectedCategoryId.value,
            isExpanded: true,
            hint: const Text('Select a category'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              controller.selectedCategoryId.value = value;
              controller.isFormDirty.value = true;
            },
            items: categories
                .map(
                  (cat) => DropdownMenuItem<String>(
                value: cat.id,
                child: Text(cat.name),
              ),
            )
                .toList(),
          );
        }),
      ],
    );
  }
}
