import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/report_issue_controller.dart';

class ImagePickerSection extends GetView<ReportIssueController> {
  const ImagePickerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text('Photos', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(' *', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: controller.selectedImages.isEmpty ? cs.errorContainer.withValues(alpha: 0.4) : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${controller.selectedImages.length}/5',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                        color: controller.selectedImages.isEmpty ? cs.onErrorContainer : cs.onPrimaryContainer)),
              )),
            ],
          ),
          const SizedBox(height: 4),
          Text('At least one photo required', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          Obx(() => controller.selectedImages.isEmpty ? _emptyState(cs) : _grid(context, cs)),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Take Photo'),
        onPressed: controller.pickImage,
      ),
    );
  }

  Widget _grid(BuildContext context, ColorScheme cs) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: controller.selectedImages.length,
          itemBuilder: (_, i) => Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(controller.selectedImages[i].path), fit: BoxFit.cover),
              ),
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: () => controller.removeImage(i),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          if (controller.selectedImages.length < 5)
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.add_a_photo_outlined, size: 16), label: const Text('Add More'), onPressed: controller.pickImage)),
          if (controller.selectedImages.length < 5) const SizedBox(width: 8),
          Expanded(child: TextButton.icon(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
            label: const Text('Remove All', style: TextStyle(color: Colors.red)),
            onPressed: controller.removeAllImages,
          )),
        ]),
      ],
    );
  }
}

