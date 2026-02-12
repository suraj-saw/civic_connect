import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/media_player/audio_player_widget.dart';
import '../widgets/media_player/video_player_widget.dart';

class IssueDetailCitizenPage extends StatelessWidget {
  final String issueId;

  const IssueDetailCitizenPage({
    super.key,
    required this.issueId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details'),
      ),
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

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(data),
                _buildLocation(data),
                _buildMediaSection(data),
                _buildTimeline(data),
                _buildReassignmentHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocation(Map<String, dynamic> data) {
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
            const SizedBox(height: 8),
            Text('Latitude: ${lat.toStringAsFixed(6)}'),
            Text('Longitude: ${lng.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Open in Maps'),
                onPressed: () => _openMap(lat, lng),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] as String?;
    final imageUrls = (data['imageUrls'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final videoUrl = data['videoUrl'] as String?;
    final audioUrl = data['audioUrl'] as String?;

    final effectiveImages = <String>[];
    if (imageUrls.isNotEmpty) {
      effectiveImages.addAll(imageUrls);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      effectiveImages.add(imageUrl);
    }

    final hasMedia =
        effectiveImages.isNotEmpty || videoUrl != null || audioUrl != null;
    if (!hasMedia) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attachments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (effectiveImages.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: effectiveImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final url = effectiveImages[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          url,
                          width: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 220,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (videoUrl != null) ...[
              VideoPlayerWidget(videoUrl: videoUrl),
              const SizedBox(height: 12),
            ],
            if (audioUrl != null) AudioPlayerWidget(audioUrl: audioUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> data) {
    final timeline = data['timeline'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Timeline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (timeline.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No updates yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              ...(() {
                final timelineItems = timeline
                    .whereType<Map<String, dynamic>>()
                    .toList()
                    .reversed
                    .toList();

                return timelineItems.asMap().entries.map((entry) {
                  final isLast = entry.key == timelineItems.length - 1;
                  final item = entry.value;
                  return _buildTimelineItem(item, isLast);
                });
              })(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, bool isLast) {
    final timestamp = item['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate())
        : 'Unknown';

    Color statusColor;
    IconData statusIcon;

    switch (item['status']) {
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
      case 'in-progress':
        statusColor = Colors.orange;
        statusIcon = Icons.construction;
        break;
      case 'assigned':
        statusColor = Colors.blue;
        statusIcon = Icons.assignment;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.report;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: statusColor.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 16),
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
                Text(
                  item['message']?.toString() ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
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

  Widget _buildReassignmentHistory() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department Transfers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .doc(issueId)
                  .collection('reassignments')
                  .orderBy('reassignedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transfers yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data();
                    final ts = data['reassignedAt'];
                    final date = ts is Timestamp
                        ? DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(ts.toDate())
                        : 'Unknown';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                      title: Text(
                        '${data['fromDept']?.toString().toUpperCase()} → ${data['toDept']?.toString().toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['reason']?.toString() ?? 'No reason provided'),
                          Text(date, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate());
    }
    return 'Unknown';
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open map');
    }
  }
}
