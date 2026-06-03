import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
        stream: FirebaseFirestore.instance.collection('issues').doc(issueId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final doc = snapshot.data;
          if (doc == null || !doc.exists || doc.data() == null) return const Center(child: Text('Issue not found'));
          final data = doc.data()!;
          final isResolved = data['status']?.toString() == 'resolved';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context, data).animate().fadeIn(duration: 350.ms),
                _location(context, data).animate().fadeIn(delay: 80.ms),
                _mediaSection(context, data).animate().fadeIn(delay: 120.ms),
                _timeline(context, data).animate().fadeIn(delay: 160.ms),
                if (isResolved) ...[
                  _feedbackHeader(context).animate().fadeIn(delay: 200.ms),
                  FeedbackSection(issueId: issueId).animate().fadeIn(delay: 220.ms),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, Map<String, dynamic> data) {
    final cs = Theme.of(context).colorScheme;
    final status = data['status']?.toString() ?? 'reported';
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data['categoryId']?.toUpperCase() ?? 'UNKNOWN',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),
          Divider(height: 20, color: cs.outline.withValues(alpha: 0.12)),
          Text(
            data['description'] ?? 'No description',
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.52,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          _metaRow(context, Icons.access_time_rounded, _fmt(data['createdAt'])),
          const SizedBox(height: 6),
          _metaRow(context, Icons.business_rounded, 'Dept: ${data['assignedToDept']?.toString().toUpperCase() ?? 'UNKNOWN'}'),
          const SizedBox(height: 6),
          _metaRow(context, Icons.person_outline_rounded, data['reporterEmail'] ?? ''),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _location(BuildContext context, Map<String, dynamic> data) {
    final location = data['location'];
    if (location is! Map) return const SizedBox.shrink();
    final lat = (location['latitude'] as num?)?.toDouble();
    final lng = (location['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.map_rounded, size: 16),
              label: const Text('Open in Maps'),
              onPressed: () async {
                final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaSection(BuildContext context, Map<String, dynamic> data) {
    var imageUrls = (data['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final single = data['imageUrl'] as String?;
    if (imageUrls.isEmpty && single != null) imageUrls.add(single);
    final audioUrl = data['audioUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    if (imageUrls.isEmpty && audioUrl == null && videoUrl == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.perm_media_outlined, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('Evidence', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Photos (${imageUrls.length})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullscreenImagePage(imageUrls: imageUrls, initialIndex: 0))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[0],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
                    errorWidget: (_, __, ___) => Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.image_not_supported_outlined, color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
            if (imageUrls.length > 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length - 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullscreenImagePage(imageUrls: imageUrls, initialIndex: i + 1))),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[i + 1],
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
                        errorWidget: (_, __, ___) => Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.broken_image_outlined, size: 16, color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (audioUrl != null) ...[
            const SizedBox(height: 16),
            Text('Voice Note', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
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

  Widget _timeline(BuildContext context, Map<String, dynamic> data) {
    final timeline = (data['timeline'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.timeline_rounded, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('Status Timeline', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 16),
          if (timeline.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(16),
                child: Text('No updates yet', style: GoogleFonts.inter(color: cs.onSurfaceVariant))))
          else
            ...timeline.reversed.toList().asMap().entries.map((e) => _timelineItem(context, e.value, e.key == timeline.length - 1)),
        ],
      ),
    );
  }

  Widget _timelineItem(BuildContext context, Map<String, dynamic> item, bool isLast) {
    final cs = Theme.of(context).colorScheme;
    final ts = item['timestamp'] as Timestamp?;
    final dateStr = ts != null ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate()) : 'Unknown';
    final status = item['status']?.toString() ?? '';
    final statusColor = _statusColor(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            if (!isLast) Container(width: 2, height: 44, color: cs.outline.withValues(alpha: 0.2)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: statusColor)),
                const SizedBox(height: 2),
                Text(item['message']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 13, height: 1.4)),
                const SizedBox(height: 2),
                Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _feedbackHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        Text('Citizen Feedback', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Icon(Icons.shield_outlined, size: 12, color: cs.onTertiaryContainer),
            const SizedBox(width: 4),
            Text('Accountability', style: GoogleFonts.inter(fontSize: 10, color: cs.onTertiaryContainer, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'in-progress': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'reopened': return Colors.deepOrange;
      default: return Colors.grey;
    }
  }

  String _fmt(dynamic ts) {
    if (ts is Timestamp) return DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
    return 'Unknown date';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.35))),
      child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
  Color _color(String s) {
    switch (s.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'in-progress': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}

