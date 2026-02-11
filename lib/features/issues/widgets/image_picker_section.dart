import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/report_issue_controller.dart';

class ImagePickerSection extends GetView<ReportIssueController> {
  const ImagePickerSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Issue Photo *',
              style: Get.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Capture one clear photo from the camera (required).',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final image = controller.selectedImage.value;
              if (image == null) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Capture Photo'),
                    onPressed: controller.captureImage,
                  ),
                );
              }

              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(image.path),
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.replay),
                          label: const Text('Retake'),
                          onPressed: controller.captureImage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text(
                            'Remove',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: controller.removeImage,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
