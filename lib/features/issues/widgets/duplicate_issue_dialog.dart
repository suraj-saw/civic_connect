import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/report_issue_controller.dart';
import '../models/duplicate_check_result.dart';

class DuplicateIssueDialog extends StatelessWidget {
  final DuplicateCheckResult result;
  const DuplicateIssueDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportIssueController>();
    final issue = result.issue;
    final cs = Theme.of(context).colorScheme;
    final dist = result.distanceMeters < 1000
        ? '${result.distanceMeters.toStringAsFixed(0)}m away'
        : '${(result.distanceMeters / 1000).toStringAsFixed(1)}km away';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 24),
        const SizedBox(width: 10),
        const Expanded(child: Text('Similar Issue Found')),
      ]),
      content: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: Text(issue.categoryId.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
                ),
                const Spacer(),
                Text(dist, style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              Text(issue.description, style: GoogleFonts.inter(fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.people_outline, size: 14, color: cs.primary),
                const SizedBox(width: 4),
                Text('${issue.duplicateReportCount} citizen${issue.duplicateReportCount == 1 ? '' : 's'} reported this',
                    style: GoogleFonts.inter(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w500)),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          Text('Would you like to report this as a new issue, or mark that you\'ve seen the same problem?',
              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () { ctrl.clearForm(); Get.back(); },
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () {
            Get.back();
            ctrl.markAsDuplicateAndGoBack(
              existingIssueId: issue.id!,
              currentCount: issue.duplicateReportCount,
              currentReporters: issue.duplicateReporters,
            );
          },
          child: const Text("I've Seen This Too"),
        ),
        ElevatedButton(
          onPressed: () async { Get.back(); await ctrl._doSubmitNewAnyway(); },
          child: const Text('Report Separately'),
        ),
      ],
    );
  }
}

// Extension to allow "report anyway" from dialog
extension ReportIssueControllerExt on ReportIssueController {
  Future<void> _doSubmitNewAnyway() => submitIssue();
}
