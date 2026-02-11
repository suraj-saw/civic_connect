import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
              if (controller.selectedVideo.value == null) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Pick Video'),
                    onPressed: controller.pickVideo,
                  ),
                );
              }

              return MediaItemCard(
                label: 'Video Selected',
                fileName: 'video.mp4',
                onRemove: controller.removeVideo,
              );
            }),
          ],
        ),
      ),
    );
  }
}