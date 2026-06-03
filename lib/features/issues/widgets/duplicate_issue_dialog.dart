import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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

    final currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final isOriginalReporter = issue.reporterEmail == currentEmail;
    final alreadyMarkedDuplicate = issue.duplicateReporters.contains(
      currentEmail,
    );

    final dist =
        result.distanceMeters < 1000
            ? '${result.distanceMeters.toStringAsFixed(0)}m away'
            : '${(result.distanceMeters / 1000).toStringAsFixed(1)}km away';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade600,
            size: 24,
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Similar Issue Found')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          issue.categoryId.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dist,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    issue.description,
                    style: GoogleFonts.inter(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${issue.duplicateReportCount} citizen${issue.duplicateReportCount == 1 ? '' : 's'} reported this',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isOriginalReporter
                  ? 'You already reported this issue. You can view its current status in My Issues.'
                  : alreadyMarkedDuplicate
                  ? 'You have already marked this issue as seen.'
                  : 'A similar issue has already been reported nearby. You can mark that you\'ve seen this problem too.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ctrl.clearForm();
            Get.back();
          },
          child: const Text('Cancel'),
        ),
        if (!isOriginalReporter && !alreadyMarkedDuplicate)
          ElevatedButton(
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
      ],
    );
  }
}
