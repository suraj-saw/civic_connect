import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'media_player/audio_player_widget.dart';
import 'media_player/video_player_widget.dart';
import 'media_player/fullscreen_image_page.dart';

class AdminIssueHeaderSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const AdminIssueHeaderSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(status: data['status']?.toString()),
              ],
            ),
            const Divider(height: 24),
            Text(
              data['description'] ?? 'No description',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Reporter', value: data['reporterEmail'] ?? 'Unknown'),
            _InfoRow(
              label: 'Department',
              value: data['assignedToDept']?.toUpperCase() ?? 'N/A',
            ),
            _InfoRow(label: 'Reported', value: formatTimestamp(data['createdAt'])),
            if (data['lastReassignedAt'] != null)
              _InfoRow(
                label: 'Last Reassigned',
                value: formatTimestamp(data['lastReassignedAt']),
              ),
          ],
        ),
      ),
    );
  }
}

class AdminIssueLocationSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(double lat, double lng) onOpenMap;

  const AdminIssueLocationSection({
    super.key,
    required this.data,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final location = data['location'];
    if (location is! Map<String, dynamic>) return const SizedBox.shrink();

    final lat = (location['latitude'] as num?)?.toDouble();
    final lng = (location['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Latitude: ${lat.toStringAsFixed(6)}'),
            Text('Longitude: ${lng.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Open in Maps'),
                onPressed: () => onOpenMap(lat, lng),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminIssueMediaSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const AdminIssueMediaSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] as String?;
    final imageUrls = (data['imageUrls'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final videoUrl = data['videoUrl'] as String?;
    final audioUrl = data['audioUrl'] as String?;

    // Merge imageUrls + legacy single imageUrl
    final images = <String>[...imageUrls];
    if (images.isEmpty && imageUrl != null && imageUrl.isNotEmpty) {
      images.add(imageUrl);
    }

    if (images.isEmpty && audioUrl == null && videoUrl == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evidence',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            // ── Photos ──────────────────────────────────────────────────
            if (images.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Photos (${images.length})',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Hero wide thumbnail
              GestureDetector(
                onTap: () => _openGallery(context, images, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          images[0],
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
                                  images.length > 1
                                      ? '1 / ${images.length}'
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
              // Thumbnail strip when multiple photos
              if (images.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _openGallery(context, images, i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          images[i],
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 72,
                            height: 72,
                            color: Colors.grey[300],
                            child:
                            const Icon(Icons.broken_image, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],

            // ── Audio ────────────────────────────────────────────────────
            if (audioUrl != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.mic_outlined,
                      size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('Audio',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              AudioPlayerWidget(audioUrl: audioUrl),
            ],

            // ── Video ────────────────────────────────────────────────────
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
}

class AdminIssueTimelineSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const AdminIssueTimelineSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final timeline = data['timeline'] as List<dynamic>? ?? [];

    if (timeline.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...timeline
                .whereType<Map<String, dynamic>>()
                .toList()
                .reversed
                .map(_buildTimelineItem),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item) {
    final statusColor = statusColorFor(item['status']?.toString());
    final timestamp = item['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate())
        : 'N/A';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item['message']?.toString() ?? ''),
                const SizedBox(height: 4),
                Text(
                  'By: ${item['updatedByEmail'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status?.toUpperCase() ?? 'UNKNOWN',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: statusColorFor(status),
    );
  }
}

Color statusColorFor(String? status) {
  switch (status?.toLowerCase()) {
    case 'resolved':
      return Colors.green;
    case 'in_progress':
    case 'in-progress':
      return Colors.orange;
    case 'assigned':
      return Colors.blue;
    case 'reassigned':
      return Colors.purple;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate());
  }
  return 'N/A';
}
