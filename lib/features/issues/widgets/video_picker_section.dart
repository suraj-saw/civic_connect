import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import '../controllers/report_issue_controller.dart';
import 'media_item_card.dart';

class VideoPickerSection extends GetView<ReportIssueController> {
  const VideoPickerSection({Key? key}) : super(key: key);

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
          Text('Video', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text('Optional — captures the full scene', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          Obx(() {
            final video = controller.selectedVideo.value;
            if (video != null) {
              return MediaItemCard(label: 'Video Selected', fileName: path.basename(video.path), onRemove: controller.removeVideo);
            }
            return SizedBox(width: double.infinity,
              child: OutlinedButton.icon(icon: const Icon(Icons.videocam_outlined), label: const Text('Capture Video'), onPressed: controller.captureVideo));
          }),
        ],
      ),
    );
  }
}
