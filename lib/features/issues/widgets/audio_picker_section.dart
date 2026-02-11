import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

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
              'Voice Description (Optional)',
              style: Get.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final audio = controller.selectedAudio.value;

              if (audio != null) {
                return MediaItemCard(
                  label: 'Audio Recorded',
                  fileName: path.basename(audio.path),
                  onRemove: controller.removeAudio,
                );
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                    controller.isRecording.value
                        ? Icons.stop_circle_outlined
                        : Icons.mic_none_outlined,
                  ),
                  label: Text(
                    controller.isRecording.value
                        ? 'Stop Recording'
                        : 'Record Voice Note',
                  ),
                  onPressed: controller.toggleAudioRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.isRecording.value
                        ? Colors.red.shade400
                        : null,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
