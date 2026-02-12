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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Photos',
                  style: Get.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Obx(() => Text(
                  '${controller.selectedImages.length}/5',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.selectedImages.isEmpty) {
                return _buildEmptyState();
              }
              return _buildImageGrid();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Take Photo'),
        // Camera only — calls pickImage() which uses ImageSource.camera
        onPressed: controller.pickImage,
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: controller.selectedImages.length,
          itemBuilder: (context, index) => _buildImageTile(index),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Add another photo — only shown when under the limit
            if (controller.selectedImages.length < 5)
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add Photo'),
                  onPressed: controller.pickImage,
                ),
              ),
            if (controller.selectedImages.length < 5)
              const SizedBox(width: 8),
            // Remove all photos
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Remove All',
                  style: TextStyle(color: Colors.red),
                ),
                // removeAllImages() takes no args — valid VoidCallback
                onPressed: controller.removeAllImages,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageTile(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(controller.selectedImages[index].path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            // Lambda passes the required index — avoids the VoidCallback mismatch
            onTap: () => controller.removeImage(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red[400],
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}