import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/models/issue_model.dart';
import './map_status_utils.dart';

class IssueDetailBottomSheet {
  static const _placeholderDescription = 'No description provided.';

  static double _sheetHeightForCount(int itemCount, double screenHeight) {
    final estimated = 170.0 + (itemCount * 162.0);
    final minHeight = screenHeight * 0.28;
    final maxHeight = screenHeight * 0.82;
    return estimated.clamp(minHeight, maxHeight);
  }

  static void _openIssueDetail(BuildContext context, String? issueId) {
    final id = issueId?.trim() ?? '';
    if (id.isEmpty) {
      AppSnackbar.show('Unavailable', 'Issue details are unavailable.');
      return;
    }

    Get.toNamed(AppRoutes.issueDetail.replaceFirst(':id', id));
  }

  static String _formatCategory(String categoryId) {
    if (categoryId.trim().isEmpty) return 'Issue';
    return categoryId
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String _normalizeDescription(String description) {
    final compact = description.trim().toLowerCase();
    if (compact.isEmpty) return _placeholderDescription.toLowerCase();
    return compact.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _nonEmptyDescription(String description) {
    final trimmed = description.trim();
    return trimmed.isEmpty ? _placeholderDescription : trimmed;
  }

  static List<_IssueDisplayGroup> _buildDisplayGroups(List<IssueModel> issues) {
    final grouped = <String, List<IssueModel>>{};

    for (final issue in issues) {
      final key =
          '${issue.categoryId.trim().toLowerCase()}|${_normalizeDescription(issue.description)}';
      grouped.putIfAbsent(key, () => <IssueModel>[]).add(issue);
    }

    final result = <_IssueDisplayGroup>[];
    for (final entry in grouped.entries) {
      final items = entry.value;
      if (items.isEmpty) continue;

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final lead = items.first;
      final totalReports = items.fold<int>(
        0,
        (sum, issue) => sum + (issue.duplicateReportCount > 0 ? issue.duplicateReportCount : 1),
      );

      result.add(
        _IssueDisplayGroup(
          leadIssue: lead,
          totalReports: totalReports,
        ),
      );
    }

    result.sort(
      (a, b) => b.leadIssue.createdAt.compareTo(a.leadIssue.createdAt),
    );
    return result;
  }

  static Widget _buildIssueImage(IssueModel issue, ColorScheme cs) {
    final imageUrl = issue.imageUrl?.trim() ?? '';
    if (imageUrl.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.image_rounded, color: cs.primary, size: 28),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 72,
            height: 72,
            color: cs.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(Icons.broken_image_outlined, color: cs.outline, size: 28),
          );
        },
      ),
    );
  }

  static Future<void> show(BuildContext context, IssueModel issue) async {
    await showGrouped(context, [issue]);
  }

  static Future<void> showGrouped(
    BuildContext context,
    List<IssueModel> issues,
  ) async {
    if (issues.isEmpty) return;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupedIssues = _buildDisplayGroups(issues);
    final totalReports = groupedIssues.fold<int>(
      0,
      (sum, group) => sum + group.totalReports,
    );
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = _sheetHeightForCount(groupedIssues.length, screenHeight);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SizedBox(
          height: sheetHeight,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primaryContainer,
                            cs.primaryContainer.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.place_rounded, color: cs.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Issues At This Pin',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            '${groupedIssues.length} issue${groupedIssues.length == 1 ? '' : 's'} • '
                            '$totalReports report${totalReports == 1 ? '' : 's'} from this location',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: cs.outlineVariant.withOpacity(0.75), height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  itemCount: groupedIssues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final group = groupedIssues[index];
                    final issue = group.leadIssue;
                    final statusColor = MapStatusUtils.getStatusColor(
                      issue.status,
                    );
                    return Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          cs.primary.withValues(alpha: isDark ? 0.10 : 0.03),
                          cs.surfaceContainerHighest,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(
                            alpha: isDark ? 0.65 : 0.88,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  MapStatusUtils.getStatusBadgeText(
                                    issue.status,
                                  ),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatCategory(issue.categoryId),
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildIssueImage(issue, cs),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _nonEmptyDescription(issue.description),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                group.totalReports == 1
                                    ? '1 report'
                                    : '${group.totalReports} reports',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _openIssueDetail(context, group.leadIssue.id);
                                },
                                child: const Text('Open'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IssueDisplayGroup {
  final IssueModel leadIssue;
  final int totalReports;

  const _IssueDisplayGroup({
    required this.leadIssue,
    required this.totalReports,
  });
}
