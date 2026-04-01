import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../issues/pages/issue_detail_admin_page.dart';
import '../controllers/home_admin_controller.dart';
import '../widgets/admin/admin_drawer.dart';

class HomeAdminPage extends StatelessWidget {
  const HomeAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<HomeAdminController>()
        ? Get.find<HomeAdminController>()
        : Get.put(HomeAdminController());

    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                'Admin Panel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              Text(
                ctrl.adminDept.value.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [const ThemeToggleButton()],
        ),
        drawer: const AdminDrawer(),
        body: Column(
          children: [
            _FilterAndSearchSection(ctrl: ctrl),
            Expanded(
              child: Obx(() {
                if (ctrl.isIssuesLoading.value) return _ShimmerList();
                if (ctrl.filteredIssues.isEmpty) {
                  return const _EmptyState(
                    title: 'No matching issues',
                    subtitle: 'Try changing search/filter criteria.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ctrl.refreshIssues(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: ctrl.filteredIssues.length,
                    itemBuilder: (context, i) {
                      final doc = ctrl.filteredIssues[i];
                      final data = doc.data();
                      final issueId = (data['id'] ?? doc.id).toString();

                      final imageUrl = data['imageUrl'] as String?;
                      final imageUrls = data['imageUrls'] as List<dynamic>?;
                      final previewUrl = imageUrl ??
                          ((imageUrls != null && imageUrls.isNotEmpty)
                              ? imageUrls.first as String?
                              : null);

                      return _AdminIssueCard(
                        data: data,
                        issueId: issueId,
                        previewUrl: previewUrl,
                        adminDept: ctrl.adminDept.value,
                        adminEmail: ctrl.adminEmail.value,
                      ).animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.06);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

class _FilterAndSearchSection extends StatelessWidget {
  final HomeAdminController ctrl;
  const _FilterAndSearchSection({required this.ctrl});

  String _sortLabel(AdminIssueSortOption option) {
    switch (option) {
      case AdminIssueSortOption.newestFirst:
        return 'Newest';
      case AdminIssueSortOption.oldestFirst:
        return 'Oldest';
      case AdminIssueSortOption.priorityHighToLow:
        return 'Priority ↓';
      case AdminIssueSortOption.priorityLowToHigh:
        return 'Priority ↑';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outline.withOpacity(0.12)),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: ctrl.updateSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search issues by keyword...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() {
                final hasQuery = ctrl.searchQuery.value.isNotEmpty;
                if (!hasQuery) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ctrl.updateSearchQuery(''),
                );
              }),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _DropdownChip<String>(
                  label: 'Category',
                  value: ctrl.selectedCategory.value,
                  items: ctrl.availableCategories,
                  displayBuilder: (v) => v == 'all' ? 'All' : v.toUpperCase(),
                  onChanged: (v) {
                    if (v != null) ctrl.updateCategory(v);
                  },
                ),
                _DropdownChip<String>(
                  label: 'Status',
                  value: ctrl.selectedStatus.value,
                  items: ctrl.availableStatuses,
                  displayBuilder: (v) => v == 'all' ? 'All' : v.toUpperCase(),
                  onChanged: (v) {
                    if (v != null) ctrl.updateStatus(v);
                  },
                ),
                _DropdownChip<AdminIssueSortOption>(
                  label: 'Sort',
                  value: ctrl.selectedSort.value,
                  items: AdminIssueSortOption.values,
                  displayBuilder: _sortLabel,
                  onChanged: (v) {
                    if (v != null) ctrl.updateSort(v);
                  },
                ),
                TextButton.icon(
                  onPressed: ctrl.clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Reset'),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DropdownChip<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) displayBuilder;
  final void Function(T?) onChanged;

  const _DropdownChip({
    required this.label,
    required this.value,
    required this.items,
    required this.displayBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: GoogleFonts.inter(
            color: cs.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
              value: e,
              child: Text('$label: ${displayBuilder(e)}'),
            ),
          )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AdminIssueCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String issueId;
  final String? previewUrl;
  final String adminDept;
  final String adminEmail;

  const _AdminIssueCard({
    required this.data,
    required this.issueId,
    this.previewUrl,
    required this.adminDept,
    required this.adminEmail,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = data['status']?.toString() ?? 'reported';
    final statusColor = _statusColor(status);

    final duplicateReportCount = (() {
      final value = data['duplicateReportCount'];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 1;
    })();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: InkWell(
        onTap: () => Get.to(
              () => IssueDetailAdminPage(
            issueId: issueId,
            adminDept: adminDept,
            adminEmail: adminEmail,
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: previewUrl != null
                      ? CachedNetworkImage(
                    imageUrl: previewUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: cs.surfaceContainerHighest),
                    errorWidget: (_, __, ___) => Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                      : Container(
                    color: cs.surfaceContainerHighest,
                    child: Icon(
                      Icons.report_outlined,
                      color: cs.onSurfaceVariant,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (data['categoryId'] ?? 'UNKNOWN')
                                .toString()
                                .toUpperCase(),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusPill(status: status, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.priority_high_rounded,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Duplicates: $duplicateReportCount',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['reporterEmail'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in-progress':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusPill({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    this.title = 'All Clear!',
    this.subtitle = 'No issues assigned to your department.',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 52,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 92,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}