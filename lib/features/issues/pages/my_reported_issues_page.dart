import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/my_issues_controller.dart';
import 'issue_detail_citizen_page.dart';

class MyReportedIssuesPage extends StatelessWidget {
  final VoidCallback? onBack;
  const MyReportedIssuesPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<MyIssuesController>()
        ? Get.find<MyIssuesController>()
        : Get.put(MyIssuesController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: onBack ?? Get.back),
        title: const Text('My Reported Issues'),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return _ShimmerList();

        if (ctrl.myIssues.isEmpty && ctrl.duplicateIssues.isEmpty) {
          return const _EmptyState();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            if (ctrl.myIssues.isNotEmpty) ...[
              _SectionHeader(title: 'My Reports', count: ctrl.myIssues.length),
              const SizedBox(height: 10),
              ...ctrl.myIssues.asMap().entries.map((e) =>
                _IssueCard(doc: e.value, isDuplicate: false)
                  .animate(delay: (e.key * 50).ms).fadeIn().slideX(begin: 0.05)),
            ],
            if (ctrl.duplicateIssues.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader(title: 'Also Reported', count: ctrl.duplicateIssues.length, subtitle: 'Issues you confirmed seeing'),
              const SizedBox(height: 10),
              ...ctrl.duplicateIssues.asMap().entries.map((e) =>
                _IssueCard(doc: e.value, isDuplicate: true)
                  .animate(delay: (e.key * 50).ms).fadeIn().slideX(begin: 0.05)),
            ],
          ],
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final String? subtitle;
  const _SectionHeader({required this.title, required this.count, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Text('$count', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text('· $subtitle', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isDuplicate;
  const _IssueCard({required this.doc, required this.isDuplicate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final issue = doc.data();
    final issueId = (issue['id'] ?? doc.id).toString();
    final imageUrl = issue['imageUrl'] as String?;
    final imageUrls = issue['imageUrls'] as List<dynamic>?;
    final previewUrl = imageUrl ?? ((imageUrls != null && imageUrls.isNotEmpty) ? imageUrls.first as String? : null);
    final status = issue['status']?.toString() ?? 'reported';
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: InkWell(
        onTap: () => Get.to(() => IssueDetailCitizenPage(issueId: issueId)),
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
                          imageUrl: previewUrl,
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
                          child: Text((issue['categoryId'] ?? 'UNKNOWN').toString().toUpperCase(),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (isDuplicate) _DuplicateBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(issue['description'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor)),
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

class _DuplicateBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Text('Also Reported', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: cs.onSecondaryContainer)),
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
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle),
            child: Icon(Icons.assignment_outlined, size: 52, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text('No reports yet', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Tap "Report an Issue" to get started.', style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 13)),
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
        itemCount: 7,
        itemBuilder: (_, __) => Container(
          height: 92, margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
