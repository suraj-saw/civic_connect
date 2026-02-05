import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReassignmentTimeline extends StatelessWidget {
  final String issueId;
  const ReassignmentTimeline({super.key, required this.issueId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reassignment History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .doc(issueId)
            .collection('reassignments')
            .orderBy('reassignedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          return ListView(
            children: snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(
                    "${d['fromDept']} → ${d['toDept']}"),
                subtitle: Text(d['reason']),
                trailing: Text(
                  DateFormat.yMd().add_jm().format(
                    (d['reassignedAt'] as Timestamp)
                        .toDate(),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
