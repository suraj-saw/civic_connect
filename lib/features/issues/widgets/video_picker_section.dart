import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import '../controllers/report_issue_controller.dart';
import 'media_player/video_player_widget.dart';

class VideoPickerSection extends GetView<ReportIssueController> {
  const VideoPickerSection({super.key});

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
          Text('Video',
              style:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text('Optional - captures the full scene',
              style: GoogleFonts.inter(
                  fontSize: 11, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Icon(Icons.videocam_off_outlined, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Video capture is not available on web. Use the mobile app to attach videos.',
                    style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ]),
            )
          else
            Obx(() {
              final video = controller.selectedVideo.value;
              if (video != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VideoPlayerWidget(
                      filePath: video.path,
                      previewAspectRatio: 5 / 4,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                        cs.primaryContainer.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: cs.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 18, color: cs.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text('Video attached',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface)),
                                const SizedBox(height: 1),
                                Text(
                                  path.basename(video.path),
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: controller.removeVideo,
                            icon: const Icon(Icons.close_rounded,
                                size: 16),
                            label: const Text('Remove'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: cs.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Capture Video'),
                      onPressed: controller.captureVideo));
            }),
        ],
      ),
    );
  }
}