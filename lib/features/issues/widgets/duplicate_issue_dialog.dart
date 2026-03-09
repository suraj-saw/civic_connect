import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/issue_category_controller.dart';
import '../controllers/report_issue_controller.dart';
import '../models/duplicate_check_result.dart';
import 'issue_status_chip.dart';

/// Dialog shown when the duplicate-detection check finds an existing issue
/// near the citizen's reported location.
class DuplicateIssueDialog extends StatelessWidget {
  final DuplicateCheckResult result;

  const DuplicateIssueDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final issue = result.issue;
    final controller = Get.find<ReportIssueController>();
    final categoryController = Get.find<IssueCategoryController>();

    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    // True when the matched issue was originally reported by the current user.
    final isOwnReport = issue.reporterEmail == currentUserEmail;
    // True when the current user has already flagged this issue as a duplicate.
    final alreadyMarked =
        currentUserEmail != null && issue.duplicateReporters.contains(currentUserEmail);

    final category = categoryController.categories
        .firstWhereOrNull((c) => c.id == issue.categoryId);
    final categoryName = category?.name ?? 'Unknown Category';

    final formattedDate = DateFormat('MMM d, yyyy').format(issue.createdAt);

    final distanceText = result.distanceInMeters < 1
        ? 'Same location'
        : result.distanceInMeters < 1000
            ? '~${result.distanceInMeters.toStringAsFixed(0)} m away'
            : '~${(result.distanceInMeters / 1000).toStringAsFixed(1)} km away';

    final descriptionSnippet = issue.description.length > 120
        ? '${issue.description.substring(0, 120)}…'
        : issue.description;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 26),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Issue Already Reported',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A similar issue has already been reported near your location.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              if (isOwnReport) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 15, color: Colors.amber),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'You reported this issue previously.',
                          style: TextStyle(fontSize: 12, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (alreadyMarked) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 15, color: Colors.green),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'You\'ve already flagged this issue.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // ── Category + Status ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.category_outlined,
                      label: categoryName,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IssueStatusChip(status: issue.status),
                ],
              ),
              const SizedBox(height: 10),

              // ── Distance + Date ────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 15, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(distanceText,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined,
                      size: 15, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(formattedDate,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 10),

              // ── Description snippet ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  descriptionSnippet,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),

              // ── Reporter count ─────────────────────────────────────────────
              // duplicateReporters holds only the citizens who flagged the issue
              // AFTER the original report. duplicateReportCount = 1 + that length.
              Builder(builder: (context) {
                // duplicateReportCount starts at 1 (the original reporter).
                // Every citizen who clicks "I've Seen This Too" increments it.
                // So when the dialog appears it already reflects all known reporters.
                final total = issue.duplicateReportCount;
                final countText = total == 1
                    ? '1 citizen has reported this issue.'
                    : '$total citizens have reported this issue in total.';
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        countText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      actions: [
        // ── Cancel — clear the form and stay on the report screen ──────────
        TextButton(
          onPressed: () {
            controller.clearForm();
            Get.back();
          },
          child: const Text('Cancel'),
        ),

        // ── Mark as duplicate — only shown when not the original reporter
        //    and not already marked. ─────────────────────────────────────────
        if (!isOwnReport && !alreadyMarked)
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.markAsDuplicateAndGoBack(
                existingIssueId: issue.id!,
                currentCount: issue.duplicateReportCount,
                currentReporters: issue.duplicateReporters,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("I've Seen This Too"),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}