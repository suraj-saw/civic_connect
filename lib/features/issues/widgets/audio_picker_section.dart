import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import '../controllers/report_issue_controller.dart';
import 'media_item_card.dart';
import 'media_player/audio_player_widget.dart';

class AudioPickerSection extends GetView<ReportIssueController> {
  const AudioPickerSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Voice Note', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text('Optional — describe the issue aloud', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          Obx(() {
            final audio = controller.selectedAudio.value;
            if (audio != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AudioPlayerWidget(filePath: audio.path),
                  const SizedBox(height: 8),
                  MediaItemCard(
                    label: 'Audio Recorded',
                    fileName: path.basename(audio.path),
                    onRemove: controller.removeAudio,
                  ),
                ],
              );
            }
            final isRecording = controller.isRecording.value;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(isRecording ? Icons.stop_circle_outlined : Icons.mic_none_outlined),
                label: Text(isRecording ? 'Stop Recording' : 'Record Voice Note'),
                onPressed: controller.toggleAudioRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecording ? Colors.red.shade400 : cs.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
