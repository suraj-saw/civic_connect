import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'media_player/audio_player_widget.dart';
import 'media_player/video_player_widget.dart';
import 'media_player/fullscreen_image_page.dart';

Color statusColorFor(String? status) {
  switch (status?.toLowerCase()) {
    case 'resolved': return Colors.green;
    case 'in-progress': return Colors.orange;
    case 'assigned': return Colors.blue;
    case 'reassigned': return Colors.purple;
    case 'rejected': return Colors.red;
    case 'reopened': return Colors.deepOrange;
    default: return Colors.grey;
  }
}

String formatTimestamp(dynamic ts) {
  if (ts is Timestamp) return DateFormat('MMM dd, yyyy • hh:mm a').format(ts.toDate());
  return 'N/A';
}

class AdminIssueHeaderSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const AdminIssueHeaderSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = data['status']?.toString();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(data['categoryId']?.toUpperCase() ?? 'UNKNOWN',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            _StatusChip(status: status),
          ]),
          Divider(height: 20, color: cs.outline.withOpacity(0.12)),
          Text(data['description'] ?? 'No description', style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
          const SizedBox(height: 14),
          _row(context, Icons.person_outline_rounded, data['reporterEmail'] ?? 'Unknown'),
          const SizedBox(height: 6),
          _row(context, Icons.business_rounded, (data['assignedToDept'] ?? 'N/A').toString().toUpperCase()),
          const SizedBox(height: 6),
          _row(context, Icons.access_time_rounded, formatTimestamp(data['createdAt'])),
          if (data['lastReassignedAt'] != null) ...[
            const SizedBox(height: 6),
            _row(context, Icons.swap_horiz_rounded, 'Reassigned: ${formatTimestamp(data['lastReassignedAt'])}'),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, size: 14, color: cs.onSurfaceVariant),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class AdminIssueLocationSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(double lat, double lng) onOpenMap;
  const AdminIssueLocationSection({super.key, required this.data, required this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    final location = data['location'];
    if (location is! Map<String, dynamic>) return const SizedBox.shrink();
    final lat = (location['latitude'] as num?)?.toDouble();
    final lng = (location['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.location_on_rounded, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('Location', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          Text('${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity,
              child: OutlinedButton.icon(icon: const Icon(Icons.map_rounded, size: 16), label: const Text('Open in Maps'), onPressed: () => onOpenMap(lat, lng))),
        ],
      ),
    );
  }
}

class AdminIssueMediaSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const AdminIssueMediaSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final imageUrl  = data['imageUrl'] as String?;
    final imageUrls = (data['imageUrls'] as List<dynamic>? ?? []).whereType<String>().toList();
    final audioUrl  = data['audioUrl'] as String?;
    final videoUrl  = data['videoUrl'] as String?;
    final images    = <String>[...imageUrls];
    if (images.isEmpty && imageUrl != null && imageUrl.isNotEmpty) images.add(imageUrl);
    if (images.isEmpty && audioUrl == null && videoUrl == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.perm_media_outlined, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('Evidence', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullscreenImagePage(imageUrls: images, initialIndex: 0))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(aspectRatio: 16 / 9,
                    child: Image.network(images[0], fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) => p == null ? child : Container(color: cs.surfaceContainerHighest))),
              ),
            ),
            if (images.length > 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal, itemCount: images.length - 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullscreenImagePage(imageUrls: images, initialIndex: i + 1))),
                    child: ClipRRect(borderRadius: BorderRadius.circular(8),
                        child: Image.network(images[i + 1], width: 60, height: 60, fit: BoxFit.cover)),
                  ),
                ),
              ),
            ],
          ],
          if (audioUrl != null) ...[
            const SizedBox(height: 16),
            Text('Audio', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            AudioPlayerWidget(audioUrl: audioUrl),
          ],
          if (videoUrl != null) ...[
            const SizedBox(height: 16),
            Text('Video', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            VideoPlayerWidget(videoUrl: videoUrl),
          ],
        ],
      ),
    );
  }
}

class AdminIssueTimelineSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const AdminIssueTimelineSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final timeline = (data['timeline'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
    if (timeline.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.timeline_rounded, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('Status Timeline', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 14),
          ...timeline.reversed.map(_buildItem),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final statusColor = statusColorFor(item['status']?.toString());
    final ts = item['timestamp'] as Timestamp?;
    final dateStr = ts != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(ts.toDate()) : 'N/A';

    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
            const SizedBox(height: 2),
            Text(item['message']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 2),
            Text('By: ${item['updatedByEmail'] ?? 'Unknown'}  •  $dateStr',
                style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
          ])),
        ]),
      );
    });
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = statusColorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.35))),
      child: Text(status?.toUpperCase() ?? 'UNKNOWN', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
