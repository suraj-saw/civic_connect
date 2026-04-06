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
          child: Obx(() {
            final progress = ctrl.uploadProgress.value.clamp(0.0, 1.0);
            final isDone = progress >= 1.0;

            return Stack(
              children: [
                // Layered backdrop for a richer production feel.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          cs.primaryContainer.withValues(alpha: 0.42),
                          cs.surface,
                          cs.surface,
                        ],
                        stops: const [0.0, 0.38, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -60,
                  left: -50,
                  child: _BackdropBlob(
                    size: 210,
                    color: cs.primary.withValues(alpha: 0.12),
                  ),
                ),
                Positioned(
                  bottom: -70,
                  right: -45,
                  child: _BackdropBlob(
                    size: 190,
                    color: cs.tertiary.withValues(alpha: 0.12),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withValues(alpha: 0.12),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _ProgressHero(progress: progress, isDone: isDone),
                            const SizedBox(height: 18),
                            Text(
                              isDone ? 'Report Submitted' : 'Submitting Your Report',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isDone
                                  ? 'Your issue has been logged successfully. The department will review it shortly.'
                                  : _progressLabel(progress),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            _ProgressBar(progress: progress),
                            const SizedBox(height: 18),
                            _ProgressMeta(progress: progress),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                children: [
                                  _UploadStep(
                                    label: 'Report details saved',
                                    done: progress >= 0.3,
                                    active: progress > 0 && progress < 0.3,
                                  ),
                                  const SizedBox(height: 12),
                                  _UploadStep(
                                    label: 'Uploading photos and media',
                                    done: progress >= 0.85,
                                    active: progress >= 0.3 && progress < 0.85,
                                  ),
                                  const SizedBox(height: 12),
                                  _UploadStep(
                                    label: 'Finalising report',
                                    done: progress >= 1.0,
                                    active: progress >= 0.85 && progress < 1.0,
                                  ),
                                ],
                              ),
                            ),
                            if (isDone) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final ctrl = Get.find<ReportIssueController>();
                                    ctrl.clearForm();
                                    ctrl.navigateCitizenToDashboard();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: cs.primary,
                                    foregroundColor: cs.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.home_rounded),
                                  label: Text(
                                    'Back to Dashboard',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
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

class _BackdropBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _BackdropBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  final double progress;
  final bool isDone;

  const _ProgressHero({required this.progress, required this.isDone});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 7,
              color: cs.surfaceContainerHighest,
            ),
          ),
          SizedBox(
            width: 120,
            height: 120,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (_, animatedValue, __) => CircularProgressIndicator(
                value: animatedValue,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                color: isDone ? Colors.green.shade600 : cs.primary,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 360),
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? Colors.green.shade50
                  : cs.primaryContainer.withValues(alpha: 0.55),
            ),
            child: Icon(
              isDone ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
              color: isDone ? Colors.green.shade700 : cs.primary,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 10,
        backgroundColor: cs.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(cs.primary),
      ),
    );
  }
}

class _ProgressMeta extends StatelessWidget {
  final double progress;

  const _ProgressMeta({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final percent = (progress * 100).toInt();

    return Row(
      children: [
        Text(
          'Progress',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$percent%',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
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
        width: 28,
        height: 28,
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
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const SizedBox.shrink(),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: done || active ? FontWeight.w600 : FontWeight.w500,
            color: done
                ? Colors.green.shade700
                : active
                    ? cs.onSurface
                    : cs.onSurfaceVariant,
          ),
        ),
      ),
    ]);
  }
}