import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class IssueDetailPage extends StatelessWidget {
  final String issueId;

  const IssueDetailPage({super.key, required this.issueId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Issue Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .doc(issueId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;
          final List timeline = data['timeline'] ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "Current Status: ${data['status'].toUpperCase()}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              const Text(
                "Status Timeline",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...timeline.map((t) {
                final ts =
                (t['timestamp'] as Timestamp?)?.toDate();

                return ListTile(
                  leading: Icon(
                    _statusIcon(t['status']),
                    color: _statusColor(t['status']),
                  ),
                  title: Text(t['message']),
                  subtitle: ts == null
                      ? null
                      : Text(
                    DateFormat.yMMMd().add_jm().format(ts),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'reported':
        return Icons.report;
      case 'assigned':
        return Icons.assignment;
      case 'in_progress':
        return Icons.build;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
