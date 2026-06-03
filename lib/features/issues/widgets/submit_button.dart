import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/report_issue_controller.dart';

class SubmitButton extends GetView<ReportIssueController> {
  const SubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final isSubmitting = controller.isSubmitting.value;
      final progress = controller.uploadProgress.value;
      return Column(
        children: [
          if (isSubmitting && progress > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: cs.surfaceContainerHighest),
            ),
            const SizedBox(height: 8),
            Text('Uploading ${(progress * 100).toInt()}%...', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : controller.submitIssue,
              icon: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit Issue Report'),
            ),
          ),
        ],
      );
    });
  }
}
