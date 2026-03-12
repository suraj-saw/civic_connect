import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../feedback/widgets/feedback_section.dart';
import '../widgets/media_player/audio_player_widget.dart';
import '../widgets/media_player/fullscreen_image_page.dart';
import '../widgets/media_player/video_player_widget.dart';

class IssueDetailCitizenPage extends StatelessWidget {
  final String issueId;

  const IssueDetailCitizenPage({super.key, required this.issueId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue Details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .doc(issueId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists || doc.data() == null) {
            return const Center(child: Text('Issue not found'));
          }

          final data = doc.data()!;
          final isResolved = data['status']?.toString() == 'resolved';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(data),
                _buildLocation(data),
                _buildMediaSection(data, context),
                _buildTimeline(data),
                if (isResolved) ...[
                  _buildFeedbackHeader(),
                  FeedbackSection(issueId: issueId),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['categoryId']?.toUpperCase() ?? 'UNKNOWN',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(data['status']?.toString()),
              ],
            ),
            const Divider(height: 24),
            Text(
              data['description'] ?? 'No description',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(data['createdAt']),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Assigned to: ${data['assignedToDept']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String label;
    switch (status?.toLowerCase()) {
      case 'resolved':
        color = Colors.green;
        label = 'RESOLVED';
        break;
      case 'in_progress':
      case 'in-progress':
        color = Colors.orange;
        label = 'IN PROGRESS';
        break;
      case 'assigned':
        color = Colors.blue;
        label = 'ASSIGNED';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'REJECTED';
        break;
      default:
        color = Colors.grey;
        label = 'REPORTED';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Widget _buildLocation(Map<String, dynamic> data) {
    final location = data['location'];
    if (location is! Map) return const SizedBox.shrink();

    final lat = (location['latitude'] as num?)?.toDouble();
    final lng = (location['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('Open in Maps'),
              onPressed: () async {
                final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Media ──────────────────────────────────────────────────────────────────

  Widget _buildMediaSection(Map<String, dynamic> data, BuildContext context) {
    var imageUrls = (data['imageUrls'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];
    final single = data['imageUrl'] as String?;
    if (imageUrls.isEmpty && single != null) imageUrls.add(single);

    final audioUrl = data['audioUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;

    if (imageUrls.isEmpty && audioUrl == null && videoUrl == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evidence',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            // ── Photos ─────────────────────────────────────────────────────
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Photos (${imageUrls.length})',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // First image — wide hero thumbnail
              GestureDetector(
                onTap: () => _openGallery(context, imageUrls, 0),
                child: Hero(
                  tag: 'img_0_$issueId',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrls[0],
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, p) => p == null
                                ? child
                                : Container(
                                color: Colors.grey[200],
                                child: const Center(
                                    child: CircularProgressIndicator())),
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                          // Overlay: photo count badge + zoom icon
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.zoom_out_map,
                                      color: Colors.white, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    imageUrls.length > 1
                                        ? '1 / ${imageUrls.length}'
                                        : 'View',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Additional thumbnails row (when more than 1 image)
              if (imageUrls.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _openGallery(context, imageUrls, i),
                      child: Hero(
                        tag: 'img_${i}_$issueId',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image.network(
                                imageUrls[i],
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image,
                                      size: 24),
                                ),
                              ),
                              // Active indicator
                              if (i == 0)
                                Positioned(
                                  bottom: 4,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],

            // ── Audio ───────────────────────────────────────────────────────
            if (audioUrl != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.mic_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('Audio',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              AudioPlayerWidget(audioUrl: audioUrl),
            ],

            // ── Video ───────────────────────────────────────────────────────
            if (videoUrl != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.videocam_outlined,
                      size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('Video',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              VideoPlayerWidget(videoUrl: videoUrl),
            ],
          ],
        ),
      ),
    );
  }

  void _openGallery(
      BuildContext context, List<String> urls, int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenImagePage(
          imageUrls: urls,
          initialIndex: startIndex,
        ),
      ),
    );
  }

  // ── Timeline ───────────────────────────────────────────────────────────────

  Widget _buildTimeline(Map<String, dynamic> data) {
    final timeline = (data['timeline'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList() ??
        [];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Timeline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (timeline.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No updates yet',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...timeline.reversed.toList().asMap().entries.map(
                    (e) =>
                    _buildTimelineItem(e.value, e.key == timeline.length - 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, bool isLast) {
    final ts = item['timestamp'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
        : 'Unknown';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: Colors.blue, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 2, height: 44, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item['status'] ?? '').toString().toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(item['message']?.toString() ?? ''),
                const SizedBox(height: 2),
                Text(dateStr,
                    style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Feedback header ────────────────────────────────────────────────────────

  Widget _buildFeedbackHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          const Text(
            'Citizen Feedback',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined,
                    size: 12, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  'Accountability',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatTimestamp(dynamic raw) {
    if (raw is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(raw.toDate());
    }
    return 'Unknown date';
  }
}