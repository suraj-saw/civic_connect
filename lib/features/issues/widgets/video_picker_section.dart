import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

import '../controllers/report_issue_controller.dart';
import 'media_item_card.dart';

class VideoPickerSection extends GetView<ReportIssueController> {
  const VideoPickerSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video (Optional)',
              style: Get.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final selectedVideo = controller.selectedVideo.value;

              if (selectedVideo == null) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Capture Video'),
                    onPressed: controller.captureVideo,
                  ),
                );
              }

              return MediaItemCard(
                label: 'Video Selected',
                fileName: path.basename(selectedVideo.path),
                onRemove: controller.removeVideo,
              );
            }),
          ],
        ),
      ),
    );
  }
}
