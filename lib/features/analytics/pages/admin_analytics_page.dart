import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analytics_summary.dart';
import '../widgets/analytics_ui_shell.dart';
import '../widgets/admin_analytics_sections.dart';
import '../widgets/citizen_analytics_sections.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Department Analytics')),
        body: const Center(child: Text('Sign in to view analytics.')),
      );
    }

    final userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Department Analytics',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: AnalyticsBackground(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDocStream,
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (userSnap.hasError || !userSnap.hasData || !userSnap.data!.exists) {
              return const Center(child: Text('Unable to load admin profile.'));
            }

            final data = userSnap.data!.data() ?? const <String, dynamic>{};
            final departmentId = (data['departmentId'] ?? '').toString().trim();
            final adminName = (data['name'] ?? 'Admin').toString();

            if (departmentId.isEmpty) {
              return const Center(child: Text('Department is not configured for this account.'));
            }

            final issueStream = FirebaseFirestore.instance
                .collection('issues')
                .where('assignedToDept', isEqualTo: departmentId)
                .snapshots();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: issueStream,
              builder: (context, issueSnap) {
                if (issueSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (issueSnap.hasError) {
                  return const Center(child: Text('Could not load department insights.'));
                }

                final docs = issueSnap.data?.docs ?? const [];
                final summary = AnalyticsSummary.fromIssues(docs);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    AdminAnalyticsHeader(
                      adminName: adminName,
                      departmentId: departmentId,
                      summary: summary,
                    ),
                    const SizedBox(height: 12),
                    AdminAnalyticsStatGrid(summary: summary),
                    const SizedBox(height: 12),
                    AdminStatusDistributionSection(summary: summary),
                    const SizedBox(height: 12),
                    AnalyticsTopSection(
                      title: 'Top Categories in Queue',
                      emptyLabel: 'No category distribution available yet.',
                      items: summary.topCategories(limit: 5),
                    ),
                    const SizedBox(height: 12),
                    AnalyticsTopSection(
                      title: 'Hotspot Areas',
                      emptyLabel: 'No location data available yet.',
                      items: summary.topAreas(limit: 5),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
