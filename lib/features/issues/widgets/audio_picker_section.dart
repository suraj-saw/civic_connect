import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/report_issue_controller.dart';
import 'media_item_card.dart';

class AudioPickerSection extends GetView<ReportIssueController> {
  const AudioPickerSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio (Optional)',
              style: Get.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.selectedAudio.value == null) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.mic_outlined),
                    label: const Text('Record Audio'),
                    onPressed: _showAudioOptions,
                  ),
                );
              }

              return MediaItemCard(
                label: 'Audio Selected',
                fileName: 'audio.mp3',
                onRemove: controller.removeAudio,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAudioOptions() {
    Get.snackbar('Info', 'Audio recording feature coming soon');
  }
}