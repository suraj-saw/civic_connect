import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/report_issue/issue_category_controller.dart';
import 'reassignment_timeline.dart';

class IssueDetailAdminPage extends StatelessWidget {
  final String issueId;
  final String adminDept;
  final String adminEmail;

  const IssueDetailAdminPage({
    super.key,
    required this.issueId,
    required this.adminDept,
    required this.adminEmail,
  });

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<IssueCategoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Issue Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.to(() => ReassignmentTimeline(issueId: issueId));
            },
            tooltip: "Reassignment History",
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .doc(issueId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(data),
                _buildMediaSection(data),
                _buildAddUpdateButton(context),
                _buildTimeline(data),
                _buildActions(context, data, categoryController),
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
                _buildStatusChip(data['status']),
              ],
            ),
            const Divider(height: 24),
            Text(
              data['description'] ?? 'No description',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Reporter", data['reporterEmail'] ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow(
              "Reported At",
              data['createdAt'] != null
                  ? DateFormat('MMM dd, yyyy • hh:mm a')
                  .format((data['createdAt'] as Timestamp).toDate())
                  : 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String label;

    switch (status) {
      case 'resolved':
        color = Colors.green;
        label = 'RESOLVED';
        break;
      case 'in_progress':
        color = Colors.orange;
        label = 'IN PROGRESS';
        break;
      case 'assigned':
        color = Colors.blue;
        label = 'ASSIGNED';
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            "$label:",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection(Map<String, dynamic> data) {
    final hasMedia = data['imageUrl'] != null ||
        data['videoUrl'] != null ||
        data['audioUrl'] != null;

    if (!hasMedia) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Media",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (data['imageUrl'] != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['imageUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (data['videoUrl'] != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.videocam, color: Colors.red),
                title: const Text("Video attached"),
              ),
            if (data['audioUrl'] != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mic, color: Colors.blue),
                title: const Text("Audio description"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddUpdateButton(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
        title: const Text(
          "Add Status Update",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showAddUpdateDialog(context),
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> data) {
    final timeline = data['timeline'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Status Timeline",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (timeline.isEmpty)
              const Center(
                child: Text(
                  "No updates yet",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...timeline.asMap().entries.map((entry) {
                final isLast = entry.key == timeline.length - 1;
                final item = entry.value as Map<String, dynamic>;
                return _buildTimelineItem(item, isLast);
              }).toList(),
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
        statusColor = Colors.orange;
        statusIcon = Icons.construction;
        break;
      case 'assigned':
        statusColor = Colors.blue;
        statusIcon = Icons.assignment;
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
                  item['status']?.toUpperCase() ?? 'UNKNOWN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['message'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "By: ${item['updatedByEmail'] ?? 'Unknown'}",
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

  Widget _buildActions(
      BuildContext context,
      Map<String, dynamic> data,
      IssueCategoryController categoryController,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.swap_horiz),
          label: const Text("Reassign Issue"),
          onPressed: () {
            _showReassignDialog(context, data['assignedToDept'],
                categoryController);
          },
        ),
      ),
    );
  }

  void _showAddUpdateDialog(BuildContext context) {
    String selectedStatus = 'in_progress';
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Status Update"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: "Status"),
              items: const [
                DropdownMenuItem(value: 'assigned', child: Text("Assigned")),
                DropdownMenuItem(
                    value: 'in_progress', child: Text("In Progress")),
                DropdownMenuItem(value: 'resolved', child: Text("Resolved")),
              ],
              onChanged: (v) => selectedStatus = v!,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Update Message",
                hintText: "Describe the progress...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Add Update"),
            onPressed: () async {
              if (messageCtrl.text.trim().isEmpty) {
                Get.snackbar("Error", "Message is required");
                return;
              }

              await _addStatusUpdate(selectedStatus, messageCtrl.text.trim());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addStatusUpdate(String status, String message) async {
    await FirebaseFirestore.instance
        .collection('issues')
        .doc(issueId)
        .update({
      'status': status,
      'timeline': FieldValue.arrayUnion([
        {
          'status': status,
          'message': message,
          'updatedBy': FirebaseAuth.instance.currentUser!.uid,
          'updatedByEmail': adminEmail,
          'timestamp': Timestamp.now(),
        }
      ]),
    });

    Get.snackbar("Success", "Status updated successfully");
  }

  void _showReassignDialog(
      BuildContext context,
      String fromDept,
      IssueCategoryController categoryController,
      ) {
    String selectedDept = fromDept;
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reassign Issue"),
        content: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDept,
                decoration: const InputDecoration(labelText: "New Department"),
                items: categoryController.categories
                    .map(
                      (cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                )
                    .toList(),
                onChanged: (v) => selectedDept = v!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Reassign"),
            onPressed: () async {
              if (selectedDept == fromDept) {
                Get.snackbar("Error", "Select a different department");
                return;
              }
              if (reasonCtrl.text.trim().isEmpty) {
                Get.snackbar("Error", "Reason is required");
                return;
              }

              await _reassignIssue(fromDept, selectedDept,
                  reasonCtrl.text.trim());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reassignIssue(
      String fromDept, String toDept, String reason) async {
    final issueRef =
    FirebaseFirestore.instance.collection('issues').doc(issueId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      txn.update(issueRef, {
        "assignedToDept": toDept,
        "status": "assigned",
      });

      txn.set(issueRef.collection('reassignments').doc(), {
        "fromDept": fromDept,
        "toDept": toDept,
        "reason": reason,
        "reassignedByUid": FirebaseAuth.instance.currentUser!.uid,
        "reassignedByEmail": adminEmail,
        "reassignedAt": FieldValue.serverTimestamp(),
      });
    });

    Get.snackbar("Success", "Issue reassigned");
  }
}