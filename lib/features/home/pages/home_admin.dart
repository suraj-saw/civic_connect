import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_dimensions.dart';
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.32),
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface,
              ],
              stops: const [0, 0.28, 1],
            ),
          ),
          child: Column(
            children: [
              _FilterAndSearchSection(ctrl: ctrl),
              _AdminOverviewStrip(ctrl: ctrl),
              Expanded(
                child: Obx(() {
                  if (ctrl.isIssuesLoading.value) return _ShimmerList();
                  if (ctrl.filteredIssues.isEmpty) {
                    return _EmptyState(
                      title: ctrl.hasActiveFilters
                          ? 'No matching issues'
                          : 'All Clear!',
                      subtitle: ctrl.hasActiveFilters
                          ? 'Try adjusting your filters or search.'
                          : 'No issues assigned to your department.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ctrl.refreshIssues(),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: ctrl.filteredIssues.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.72,
                      ),
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
                        ).animate(delay: (i * 45).ms).fadeIn().slideY(begin: 0.08);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _AdminOverviewStrip extends StatelessWidget {
  final HomeAdminController ctrl;
  const _AdminOverviewStrip({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final total = ctrl.filteredIssues.length;
      final inProgress = ctrl.filteredIssues
          .where((e) => (e.data()['status'] ?? '').toString().toLowerCase() == 'in-progress')
          .length;
      final urgent = ctrl.filteredIssues.where((e) {
        final raw = e.data()['duplicateReportCount'];
        final count = raw is num ? raw.toInt() : 1;
        return count >= 5;
      }).length;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Expanded(child: _MetricTile(label: 'Visible', value: '$total', color: cs.primary)),
            Expanded(child: _MetricTile(label: 'In Progress', value: '$inProgress', color: Colors.orange)),
            Expanded(child: _MetricTile(label: 'Urgent', value: '$urgent', color: Colors.redAccent)),
          ],
        ),
      );
    });
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter & Search Section
// ─────────────────────────────────────────────────────────────────────────────

class _FilterAndSearchSection extends StatefulWidget {
  final HomeAdminController ctrl;
  const _FilterAndSearchSection({required this.ctrl});

  @override
  State<_FilterAndSearchSection> createState() =>
      _FilterAndSearchSectionState();
}

class _FilterAndSearchSectionState extends State<_FilterAndSearchSection> {
  late final TextEditingController _searchCtrl;

  HomeAdminController get ctrl => widget.ctrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: ctrl.searchQuery.value);

    // Keep the TextField in sync when clearFilters() is called externally
    ever(ctrl.searchQuery, (String val) {
      if (_searchCtrl.text != val) {
        _searchCtrl.text = val;
        _searchCtrl.selection =
            TextSelection.collapsed(offset: val.length);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _sortLabel(AdminIssueSortOption option) {
    switch (option) {
      case AdminIssueSortOption.newestFirst:
        return 'Newest First';
      case AdminIssueSortOption.oldestFirst:
        return 'Oldest First';
      case AdminIssueSortOption.priorityHighToLow:
        return 'Most Reported';
      case AdminIssueSortOption.priorityLowToHigh:
        return 'Least Reported';
    }
  }

  String _statusLabel(String s) {
    if (s == 'all') return 'All Statuses';
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ──
          TextField(
            controller: _searchCtrl,
            onChanged: ctrl.updateSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search by keyword, email, status…',
              hintStyle: GoogleFonts.inter(fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: Obx(() {
                if (ctrl.searchQuery.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  splashRadius: 18,
                  onPressed: () => ctrl.updateSearchQuery(''),
                );
              }),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Filter chips row ──
          Obx(() {
            final hasActive = ctrl.hasActiveFilters;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Status filter
                  _FilterChip<String>(
                    icon: Icons.flag_outlined,
                    label: 'Status',
                    selectedLabel: _statusLabel(ctrl.selectedStatus.value),
                    isActive: ctrl.selectedStatus.value != 'all',
                    value: ctrl.selectedStatus.value,
                    items: ctrl.availableStatuses,
                    displayBuilder: _statusLabel,
                    onChanged: (v) {
                      if (v != null) ctrl.updateStatus(v);
                    },
                  ),
                  const SizedBox(width: 8),

                  // Sort filter
                  _FilterChip<AdminIssueSortOption>(
                    icon: Icons.sort_rounded,
                    label: 'Sort',
                    selectedLabel: _sortLabel(ctrl.selectedSort.value),
                    isActive: ctrl.selectedSort.value !=
                        AdminIssueSortOption.newestFirst,
                    value: ctrl.selectedSort.value,
                    items: AdminIssueSortOption.values,
                    displayBuilder: _sortLabel,
                    onChanged: (v) {
                      if (v != null) ctrl.updateSort(v);
                    },
                  ),

                  // Reset — only shown when something is active
                  if (hasActive) ...[
                    const SizedBox(width: 8),
                    _ResetButton(onTap: ctrl.clearFilters),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic filter chip (dropdown style)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final String selectedLabel;
  final bool isActive;
  final T value;
  final List<T> items;
  final String Function(T) displayBuilder;
  final void Function(T?) onChanged;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.selectedLabel,
    required this.isActive,
    required this.value,
    required this.items,
    required this.displayBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = cs.primary;
    final bgColor = isActive
        ? activeColor.withValues(alpha: 0.1)
        : cs.surfaceContainerHighest.withValues(alpha: 0.6);
    final borderColor = isActive
        ? activeColor.withValues(alpha: 0.4)
        : cs.outline.withValues(alpha: 0.2);
    final labelColor = isActive ? activeColor : cs.onSurfaceVariant;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: labelColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          style: GoogleFonts.inter(
            color: labelColor,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
          selectedItemBuilder: (_) => items.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: labelColor),
                const SizedBox(width: 4),
                Text(
                  selectedLabel,
                  style: GoogleFonts.inter(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    displayBuilder(e),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: cs.onSurface,
                      fontWeight: e == value
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reset button
// ─────────────────────────────────────────────────────────────────────────────

class _ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_off_rounded,
                size: 14, color: cs.error),
            const SizedBox(width: 4),
            Text(
              'Reset',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.error,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Issue Card
// ─────────────────────────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Get.to(
              () => IssueDetailAdminPage(
            issueId: issueId,
            adminDept: adminDept,
            adminEmail: adminEmail,
          ),
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.cardRadius)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: previewUrl != null
                    ? CachedNetworkImage(
                        imageUrl: previewUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
                        errorWidget: (_, __, ___) => Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
                        ),
                      )
                    : Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.report_outlined, color: cs.onSurfaceVariant, size: 34),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (data['categoryId'] ?? 'UNKNOWN').toString().toUpperCase(),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        (data['description'] ?? '').toString(),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: cs.onSurfaceVariant,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(status: status, color: statusColor),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.copy_outlined, size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$duplicateReportCount report${duplicateReportCount == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(fontSize: 10.5, color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _createdText(data['createdAt']),
                      style: GoogleFonts.inter(fontSize: 10, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  String _createdText(dynamic createdAt) {
    DateTime? dt;
    if (createdAt is DateTime) dt = createdAt;
    if (createdAt is Timestamp) dt = createdAt.toDate();
    if (dt == null) return 'unknown';

    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusPill({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final compactLabel = status.replaceAll('-', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        compactLabel,
        style: GoogleFonts.inter(
          fontSize: 8.8,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

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
              color: cs.primaryContainer.withValues(alpha: 0.5),
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
            style:
                GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer loading list
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surface,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}