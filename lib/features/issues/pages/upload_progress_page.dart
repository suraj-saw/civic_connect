import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/report_issue_controller.dart';

class UploadProgressPage extends StatelessWidget {
  const UploadProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportIssueController>();
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false, // prevent back navigation during upload
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Obx(() {
              final progress = ctrl.uploadProgress.value;
              final isDone = progress >= 1.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? Colors.green.shade50
                          : cs.primaryContainer.withOpacity(0.5),
                    ),
                    child: Center(
                      child: isDone
                          ? Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade600, size: 48)
                          : Icon(Icons.cloud_upload_outlined,
                          color: cs.primary, size: 48),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    isDone ? 'Report Submitted!' : 'Submitting Your Report',
                    style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    isDone
                        ? 'Your issue has been reported successfully.\nThe department will review it shortly.'
                        : _progressLabel(progress),
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                        height: 1.5),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 36),

                  // Progress bar
                  if (!isDone) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500),
                    ),
                  ],

                  // Upload steps
                  const SizedBox(height: 36),
                  _UploadStep(
                    label: 'Report details saved',
                    done: progress >= 0.3,
                    active: progress > 0 && progress < 0.3,
                  ),
                  const SizedBox(height: 12),
                  _UploadStep(
                    label: 'Uploading photos & media',
                    done: progress >= 0.85,
                    active: progress >= 0.3 && progress < 0.85,
                  ),
                  const SizedBox(height: 12),
                  _UploadStep(
                    label: 'Finalising report',
                    done: progress >= 1.0,
                    active: progress >= 0.85 && progress < 1.0,
                  ),

                  if (isDone) ...[
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final ctrl = Get.find<ReportIssueController>();
                          ctrl.clearForm();
                          ctrl.navigateCitizenToDashboard(); // make _navigateCitizenToDashboard public by removing underscore in controller
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Back to Dashboard'),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  String _progressLabel(double progress) {
    if (progress < 0.3) return 'Saving your report details...';
    if (progress < 0.85) return 'Uploading photos and media.\nThis may take a moment depending on your connection.';
    return 'Finalising your report...';
  }
}

class _UploadStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _UploadStep({
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done
              ? Colors.green.shade500
              : active
              ? cs.primary
              : cs.surfaceContainerHighest,
        ),
        child: Center(
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : active
              ? const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
              : const SizedBox.shrink(),
        ),
      ),
      const SizedBox(width: 14),
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: done || active ? FontWeight.w600 : FontWeight.w400,
          color: done
              ? Colors.green.shade700
              : active
              ? cs.onSurface
              : cs.onSurfaceVariant,
        ),
      ),
    ]);
  }
}