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
              Text('Admin Panel', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
              Text(ctrl.adminDept.value.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          centerTitle: true,
          actions: [const ThemeToggleButton()],
        ),
        drawer: const AdminDrawer(),
        body: Obx(() {
          if (ctrl.isIssuesLoading.value) return _ShimmerList();
          if (ctrl.assignedIssues.isEmpty) return const _EmptyState();

          return RefreshIndicator(
            onRefresh: () async => ctrl.refreshIssues(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: ctrl.assignedIssues.length,
              itemBuilder: (context, i) {
                final doc = ctrl.assignedIssues[i];
                final data = doc.data();
                final issueId = (data['id'] ?? doc.id).toString();
                final imageUrl = data['imageUrl'] as String?;
                final imageUrls = data['imageUrls'] as List<dynamic>?;
                final previewUrl = imageUrl ?? ((imageUrls != null && imageUrls.isNotEmpty) ? imageUrls.first as String? : null);

                return _AdminIssueCard(
                  data: data, issueId: issueId, previewUrl: previewUrl,
                  adminDept: ctrl.adminDept.value, adminEmail: ctrl.adminEmail.value,
                ).animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.06);
              },
            ),
          );
        }),
      );
    });
  }
}

class _AdminIssueCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String issueId;
  final String? previewUrl;
  final String adminDept;
  final String adminEmail;

  const _AdminIssueCard({required this.data, required this.issueId, this.previewUrl, required this.adminDept, required this.adminEmail});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = data['status']?.toString() ?? 'reported';
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: InkWell(
        onTap: () => Get.to(() => IssueDetailAdminPage(issueId: issueId, adminDept: adminDept, adminEmail: adminEmail)),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64, height: 64,
                  child: previewUrl != null
                      ? CachedNetworkImage(
                          imageUrl: previewUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
                          errorWidget: (_, __, ___) => Container(color: cs.surfaceContainerHighest,
                              child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant)),
                        )
                      : Container(color: cs.surfaceContainerHighest,
                          child: Icon(Icons.report_outlined, color: cs.onSurfaceVariant, size: 28)),
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
                          child: Text((data['categoryId'] ?? 'UNKNOWN').toString().toUpperCase(),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        _StatusPill(status: status, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(data['description'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(child: Text(data['reporterEmail'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'in-progress': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
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
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline_rounded, size: 52, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text('All Clear!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('No issues assigned to your department.', style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 13)),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
