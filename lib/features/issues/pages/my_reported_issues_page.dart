import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/my_issues_controller.dart';
import 'issue_detail_citizen_page.dart';

class MyReportedIssuesPage extends StatelessWidget {
  final VoidCallback? onBack;

  const MyReportedIssuesPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<MyIssuesController>()
        ? Get.find<MyIssuesController>()
        : Get.put(MyIssuesController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? Get.back,
        ),
        title: const Text(
          'My Reported Issues',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasOwn = controller.myIssues.isNotEmpty;
        final hasDuplicates = controller.duplicateIssues.isNotEmpty;

        if (!hasOwn && !hasDuplicates) {
          return const Center(
            child: Text('You have not reported any issues yet.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (hasOwn) ...[
              _SectionHeader(title: 'My Reports', count: controller.myIssues.length),
              ...controller.myIssues.map(
                    (doc) => _IssueCard(doc: doc, isDuplicate: false),
              ),
            ],
            if (hasDuplicates) ...[
              const SizedBox(height: 8),
              _SectionHeader(
                title: 'Also Reported',
                count: controller.duplicateIssues.length,
                subtitle: 'Issues you confirmed seeing',
              ),
              ...controller.duplicateIssues.map(
                    (doc) => _IssueCard(doc: doc, isDuplicate: true),
              ),
            ],
          ],
        );
      }),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final String? subtitle;

  const _SectionHeader({
    required this.title,
    required this.count,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            '$title ($count)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              '· $subtitle',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Issue card ────────────────────────────────────────────────────────────────

class _IssueCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isDuplicate;

  const _IssueCard({required this.doc, required this.isDuplicate});

  @override
  Widget build(BuildContext context) {
    final issue = doc.data();
    final issueId = issue['id'] ?? doc.id;

    final imageUrl = issue['imageUrl'] as String?;
    final imageUrls = issue['imageUrls'] as List<dynamic>?;
    final previewImageUrl = imageUrl ??
        ((imageUrls != null && imageUrls.isNotEmpty)
            ? imageUrls.first as String?
            : null);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _IssueLeadingImage(imageUrl: previewImageUrl),
        title: Row(
          children: [
            Expanded(
              child: Text(
                issue['categoryId']?.toString().toUpperCase() ?? 'UNKNOWN',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isDuplicate) _DuplicateBadge(),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              issue['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Status: ${issue['status']}',
              style: TextStyle(
                color: issue['status'] == 'resolved'
                    ? Colors.green
                    : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => Get.to(() => IssueDetailCitizenPage(issueId: issueId.toString())),
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _DuplicateBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        'Also Reported',
        style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
      ),
    );
  }
}

class _IssueLeadingImage extends StatelessWidget {
  final String? imageUrl;

  const _IssueLeadingImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const Icon(Icons.report);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 50,
        height: 50,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
          },
        ),
      ),
    );
  }
}