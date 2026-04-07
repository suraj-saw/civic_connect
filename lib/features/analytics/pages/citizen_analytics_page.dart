import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analytics_summary.dart';
import '../widgets/analytics_ui_shell.dart';
import '../widgets/citizen_analytics_sections.dart';

class CitizenAnalyticsPage extends StatelessWidget {
  const CitizenAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    if (user?.email == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Analytics')),
        body: const Center(child: Text('Sign in to view analytics.')),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('issues')
        .where('reporterEmail', isEqualTo: user!.email)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Analytics',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: AnalyticsBackground(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Could not load analytics right now.'));
            }

            final docs = snapshot.data?.docs ?? const [];
            final summary = AnalyticsSummary.fromIssues(docs);

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No reported issues yet. Submit your first issue to unlock insights.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                CitizenAnalyticsHeadlineCard(
                  title: 'Resolution Rate',
                  value: '${summary.resolutionRate.toStringAsFixed(1)}%',
                  subtitle:
                      '${summary.resolved} resolved out of ${summary.total} reports',
                ),
                const SizedBox(height: 12),
                CitizenAnalyticsStatGrid(summary: summary),
                const SizedBox(height: 12),
                CitizenStatusDistributionSection(summary: summary),
                const SizedBox(height: 12),
                AnalyticsTopSection(
                  title: 'Top Reported Categories',
                  emptyLabel: 'No categories available yet.',
                  items: summary.topCategories(),
                ),
                const SizedBox(height: 12),
                AnalyticsTopSection(
                  title: 'Frequent Locations',
                  emptyLabel: 'No location information available yet.',
                  items: summary.topAreas(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
