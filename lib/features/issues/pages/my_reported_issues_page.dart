import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_dimensions.dart';
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.28),
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
            ],
            stops: const [0, 0.24, 1],
          ),
        ),
        child: Obx(() {
          if (ctrl.isLoading.value) return _ShimmerList();

          if (ctrl.myIssues.isEmpty && ctrl.duplicateIssues.isEmpty) {
            return const _EmptyState();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _CitizenSummaryHeader(
                myCount: ctrl.myIssues.length,
                duplicateCount: ctrl.duplicateIssues.length,
              ),
              const SizedBox(height: 16),
              if (ctrl.myIssues.isNotEmpty) ...[
                _SectionHeader(title: 'My Reports', count: ctrl.myIssues.length),
                const SizedBox(height: 10),
                ...ctrl.myIssues.asMap().entries.map((e) =>
                  _IssueCard(doc: e.value, isDuplicate: false)
                    .animate(delay: (e.key * 45).ms).fadeIn().slideX(begin: 0.05)),
              ],
              if (ctrl.duplicateIssues.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeader(title: 'Also Reported', count: ctrl.duplicateIssues.length, subtitle: 'Issues you confirmed seeing'),
                const SizedBox(height: 10),
                ...ctrl.duplicateIssues.asMap().entries.map((e) =>
                  _IssueCard(doc: e.value, isDuplicate: true)
                    .animate(delay: (e.key * 45).ms).fadeIn().slideX(begin: 0.05)),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _CitizenSummaryHeader extends StatelessWidget {
  final int myCount;
  final int duplicateCount;
  const _CitizenSummaryHeader({required this.myCount, required this.duplicateCount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = myCount + duplicateCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Issue Overview', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$total total related reports', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ),
          _CountPill(label: 'Mine', value: '$myCount'),
          const SizedBox(width: 6),
          _CountPill(label: 'Also', value: '$duplicateCount'),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final String value;
  const _CountPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Text('$count', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
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
      constraints: const BoxConstraints(minHeight: AppDimensions.issueCardMinHeight),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Get.to(() => IssueDetailCitizenPage(issueId: issueId)),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72, height: 72,
                  child: previewUrl != null
                      ? CachedNetworkImage(
                          imageUrl: previewUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
                          errorWidget: (_, __, ___) => Container(color: cs.surfaceContainerHighest,
                              child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant)),
                        )
                      : Container(color: cs.surfaceContainerHighest,
                          child: Icon(Icons.report_outlined, color: cs.onSurfaceVariant, size: 30)),
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
                    SizedBox(
                      height: AppDimensions.twoLineTextHeight,
                      child: Text(
                        issue['description'] ?? '',
                        style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor)),
                        ),
                        const Spacer(),
                        Text(
                          _createdText(issue['createdAt']),
                          style: GoogleFonts.inter(fontSize: 10, color: cs.onSurfaceVariant),
                        ),
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
          height: AppDimensions.issueCardMinHeight, margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
