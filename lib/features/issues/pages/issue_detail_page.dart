import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../widgets/issue_status_chip.dart';
import '../widgets/issue_info_section.dart';
import '../widgets/media_player/audio_player_widget.dart';
import '../widgets/media_player/video_player_widget.dart';
import '../widgets/resolution/resolution_card.dart';
import '../widgets/resolution/resolution_form.dart';
import '../widgets/status/status_action_card.dart';
import '../widgets/status/rejection_dialog.dart';

class IssueDetailPage extends StatefulWidget {
  final String issueId;

  const IssueDetailPage({super.key, required this.issueId});

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  bool _isSubmittingResolution = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Issue Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => {},
                // _navigateToTimeline(),
            tooltip: "View History",
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .doc(widget.issueId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("Issue not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Chip
                IssueStatusChip(status: data['status'] ?? 'unknown'),
                const SizedBox(height: 16),

                // Reporter Information
                IssueInfoSection(
                  title: "Reporter Information",
                  rows: [
                    InfoRow("Email", data['reporterEmail'] ?? 'N/A'),
                    InfoRow("Reported On", DateFormatter.formatTimestamp(data['createdAt'])),
                  ],
                ),
                const SizedBox(height: 16),

                // Issue Details
                IssueInfoSection(
                  title: "Issue Details",
                  rows: [
                    InfoRow("Category", (data['categoryId'] ?? 'Unknown').toUpperCase()),
                    InfoRow("Department", (data['assignedToDept'] ?? 'Unknown').toUpperCase()),
                    if (data['lastReassignedAt'] != null)
                      InfoRow("Last Reassigned", DateFormatter.formatTimestamp(data['lastReassignedAt'])),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                _buildSection("Description", _buildDescriptionCard(data['description'])),

                // Media Evidence
                if (data['imageUrl'] != null)
                  _buildSection("Photo Evidence", _buildImageCard(data['imageUrl'])),

                if (data['audioUrl'] != null)
                  _buildSection("Voice Description", AudioPlayerWidget(audioUrl: data['audioUrl'])),

                if (data['videoUrl'] != null)
                  _buildSection("Video Evidence", VideoPlayerWidget(videoUrl: data['videoUrl'])),

                // Location
                if (data['location'] != null)
                  _buildSection("Location", _buildLocationCard(data['location'])),

                // Resolution
                if (data['status'] == 'resolved' && data['resolution'] != null)
                  _buildSection("Resolution", ResolutionCard(resolution: data['resolution'])),

                // Rejection
                if (data['status'] == 'rejected')
                  _buildSection("Rejection Details", _buildRejectionCard(data)),

                // Status Actions
                if (data['status'] != 'resolved' && data['status'] != 'rejected')
                  _buildSection(
                    "Update Status",
                    StatusActionCard(
                      currentStatus: data['status'],
                      onMarkInProgress: () => _updateStatus('in-progress'),
                      onReject: _showRejectDialog,
                    ),
                  ),

                // Resolution Form
                if (data['status'] == 'in-progress')
                  _buildSection(
                    "Submit Resolution",
                    ResolutionForm(
                      onSubmit: _submitResolution,
                      isSubmitting: _isSubmittingResolution,
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  /* ================= HELPER WIDGETS ================= */

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: AppTextStyles.sectionTitle),
        ),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDescriptionCard(String? description) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          description ?? 'No description provided',
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stack) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Failed to load image')),
          );
        },
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    final lat = location['latitude'] ?? 0.0;
    final lng = location['longitude'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Latitude: ${lat.toStringAsFixed(6)}"),
            const SizedBox(height: 4),
            Text("Longitude: ${lng.toStringAsFixed(6)}"),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("View on Map"),
                onPressed: () {
                  // TODO: Implement map view
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionCard(Map<String, dynamic> data) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Reason:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(data['rejectionReason'] ?? 'No reason provided'),
            const SizedBox(height: 8),
            Text(
              "Rejected on: ${DateFormatter.formatTimestamp(data['rejectedAt'])}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= ACTIONS ================= */

  // void _navigateToTimeline() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ReassignmentTimeline(issueId: widget.issueId),
  //     ),
  //   );
  // }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .update({
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      Get.snackbar("Success", "Status updated to ${newStatus.replaceAll('-', ' ')}");
    } catch (e) {
      Get.snackbar("Error", "Failed to update status: ${e.toString()}");
    }
  }

  Future<void> _showRejectDialog() async {
    final reason = await RejectionDialog.show(context);

    if (reason != null) {
      try {
        await FirebaseFirestore.instance
            .collection('issues')
            .doc(widget.issueId)
            .update({
          'status': 'rejected',
          'rejectionReason': reason,
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
        });

        Get.snackbar("Success", "Issue rejected");
      } catch (e) {
        Get.snackbar("Error", "Failed to reject issue: ${e.toString()}");
      }
    }
  }

  Future<void> _submitResolution(File image, String notes) async {
    setState(() {
      _isSubmittingResolution = true;
    });

    try {
      // TODO: Upload image to storage and get URL
      final String imageUrl = ""; // Upload logic here

      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .update({
        'status': 'resolved',
        'resolution': {
          'imageUrl': imageUrl,
          'notes': notes,
          'resolvedAt': FieldValue.serverTimestamp(),
          'resolvedBy': FirebaseAuth.instance.currentUser?.uid,
        },
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar("Success", "Issue marked as resolved");
      Navigator.pop(context);
    } catch (e) {
      Get.snackbar("Error", "Failed to submit resolution: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingResolution = false;
        });
      }
    }
  }
}