import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReassignmentTimelinePage extends StatelessWidget {
  final String issueId;
  const ReassignmentTimelinePage({super.key, required this.issueId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Reassignment History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('issues').doc(issueId)
            .collection('reassignments')
            .orderBy('reassignedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.swap_horiz_rounded, size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('No reassignments yet', style: GoogleFonts.inter(fontSize: 16, color: cs.onSurfaceVariant)),
              ]).animate().fadeIn(),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final ts = data['reassignedAt'] as Timestamp?;
              final dateStr = ts != null ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate()) : 'N/A';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(8)),
                        child: Text(data['fromDept']?.toString().toUpperCase() ?? '', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onErrorContainer))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded, size: 16, color: cs.onSurfaceVariant)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                        child: Text(data['toDept']?.toString().toUpperCase() ?? '', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer))),
                  ]),
                  const SizedBox(height: 8),
                  Text(data['reason'] ?? '', style: GoogleFonts.inter(fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('By: ${data['reassignedByEmail'] ?? 'Unknown'}  *  $dateStr',
                      style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
                ]),
              ).animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.05);
            },
          );
        },
      ),
    );
  }
}

