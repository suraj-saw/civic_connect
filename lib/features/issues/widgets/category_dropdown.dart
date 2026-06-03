import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/issue_category_controller.dart';
import '../controllers/report_issue_controller.dart';

class CategoryDropdown extends GetView<ReportIssueController> {
  const CategoryDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryCtrl = Get.find<IssueCategoryController>();
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Category', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(' *', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        Obx(() {
          if (categoryCtrl.isLoading.value) return const LinearProgressIndicator();
          if (categoryCtrl.categories.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.errorContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
              child: Text('No categories available. Try again later.', style: GoogleFonts.inter(fontSize: 13, color: cs.onErrorContainer)),
            );
          }
          return DropdownButtonFormField<String>(
            initialValue: controller.selectedCategoryId.value,
            isExpanded: true,
            hint: const Text('Select a category'),
            decoration: const InputDecoration(),
            onChanged: (v) {
              controller.selectedCategoryId.value = v;
              controller.isFormDirty.value = true;
            },
            items: categoryCtrl.categories
                .map((cat) => DropdownMenuItem<String>(value: cat.id, child: Text(cat.name)))
                .toList(),
          );
        }),
      ],
    );
  }
}

