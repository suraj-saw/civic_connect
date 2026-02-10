import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../services/firebase_storage_service.dart';
import '../../services/media_upload_service.dart';
import '../home/admin/reassignment_timeline.dart';


class IssueDetailPage extends StatefulWidget {
  final String issueId;

  const IssueDetailPage({super.key, required this.issueId});

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  File? _resolutionImage;
  final TextEditingController _resolutionNotesController = TextEditingController();
  bool _isSubmittingResolution = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    _resolutionNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Issue Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReassignmentTimeline(issueId: widget.issueId),
                ),
              );
            },
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
                _buildStatusChip(data['status'] ?? 'unknown'),
                const SizedBox(height: 16),

                // Reporter Information
                _buildSectionTitle("Reporter Information"),
                _buildInfoCard([
                  _buildInfoRow("Email", data['reporterEmail'] ?? 'N/A'),
                  _buildInfoRow("Reported On", _formatTimestamp(data['createdAt'])),
                ]),
                const SizedBox(height: 16),

                // Issue Details
                _buildSectionTitle("Issue Details"),
                _buildInfoCard([
                  _buildInfoRow("Category", (data['categoryId'] ?? 'Unknown').toUpperCase()),
                  _buildInfoRow("Department", (data['assignedToDept'] ?? 'Unknown').toUpperCase()),
                  if (data['lastReassignedAt'] != null)
                    _buildInfoRow("Last Reassigned", _formatTimestamp(data['lastReassignedAt'])),
                ]),
                const SizedBox(height: 16),

                // Description
                _buildSectionTitle("Description"),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      data['description'] ?? 'No description provided',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Image Evidence
                if (data['imageUrl'] != null) ...[
                  _buildSectionTitle("Photo Evidence"),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      data['imageUrl'],
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
                          child: Center(
                            child: Text('Failed to load image'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Audio Evidence
                if (data['audioUrl'] != null) ...[
                  _buildSectionTitle("Voice Description"),
                  _buildAudioPlayer(data['audioUrl']),
                  const SizedBox(height: 16),
                ],

                // Video Evidence (if exists)
                if (data['videoUrl'] != null) ...[
                  _buildSectionTitle("Video Evidence"),
                  _buildVideoPlayer(data['videoUrl']),
                  const SizedBox(height: 16),
                ],

                // Location Information
                if (data['location'] != null) ...[
                  _buildSectionTitle("Location"),
                  _buildLocationCard(data['location']),
                  const SizedBox(height: 16),
                ],

                // Resolution Section (if issue is resolved)
                if (data['status'] == 'resolved' && data['resolution'] != null) ...[
                  _buildSectionTitle("Resolution"),
                  _buildResolutionCard(data['resolution']),
                  const SizedBox(height: 16),
                ],

                // Rejection Reason (if rejected)
                if (data['status'] == 'rejected') ...[
                  _buildSectionTitle("Rejection Details"),
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Reason:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(data['rejectionReason'] ?? 'No reason provided'),
                          const SizedBox(height: 8),
                          Text(
                            "Rejected on: ${_formatTimestamp(data['rejectedAt'])}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Status Update Actions
                if (data['status'] != 'resolved' && data['status'] != 'rejected') ...[
                  _buildSectionTitle("Update Status"),
                  _buildStatusActions(data),
                  const SizedBox(height: 16),
                ],

                // Resolution Submission (if in-progress)
                if (data['status'] == 'in-progress') ...[
                  _buildSectionTitle("Submit Resolution"),
                  _buildResolutionForm(),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /* ================= UI COMPONENTS ================= */

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'reported':
        chipColor = Colors.orange;
        icon = Icons.report;
        break;
      case 'assigned':
        chipColor = Colors.blue;
        icon = Icons.assignment;
        break;
      case 'in-progress':
        chipColor = Colors.amber;
        icon = Icons.hourglass_bottom;
        break;
      case 'resolved':
        chipColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        chipColor = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(String audioUrl) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.onPlayerStateChanged,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.toString().contains('playing') ?? false;

                return Row(
                  children: [
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                      iconSize: 48,
                      color: Theme.of(context).primaryColor,
                      onPressed: () async {
                        if (isPlaying) {
                          await _audioPlayer.pause();
                        } else {
                          await _audioPlayer.play(UrlSource(audioUrl));
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Voice Description",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          StreamBuilder<Duration>(
                            stream: _audioPlayer.onPositionChanged,
                            builder: (context, snapshot) {
                              final position = snapshot.data ?? Duration.zero;
                              return Text(
                                _formatDuration(position),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: () async {
                        await _audioPlayer.stop();
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<Duration>(
              stream: _audioPlayer.onPositionChanged,
              builder: (context, posSnapshot) {
                final position = posSnapshot.data ?? Duration.zero;

                return StreamBuilder<Duration?>(
                  stream: _audioPlayer.onDurationChanged,
                  builder: (context, durSnapshot) {
                    final duration = durSnapshot.data ?? Duration.zero;

                    return LinearProgressIndicator(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    if (_videoController == null || _videoController!.dataSource != videoUrl) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
        });
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: _isVideoInitialized
                ? _videoController!.value.aspectRatio
                : 16 / 9,
            child: _isVideoInitialized
                ? VideoPlayer(_videoController!)
                : const Center(child: CircularProgressIndicator()),
          ),
          if (_isVideoInitialized)
            Container(
              color: Colors.black87,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _videoController!.value.isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                    },
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.blue,
                        bufferedColor: Colors.grey,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: () {
                      // Implement fullscreen if needed
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    final lat = location['latitude'] ?? 0.0;
    final lng = location['longitude'] ?? 0.0;
    final accuracy = location['accuracy'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Latitude", lat.toStringAsFixed(6)),
            _buildInfoRow("Longitude", lng.toStringAsFixed(6)),
            _buildInfoRow("Accuracy", "±${accuracy.toStringAsFixed(1)} meters"),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("View on Map"),
                onPressed: () {
                  // TODO: Open in Google Maps or implement map view
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionCard(Map<String, dynamic> resolution) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resolution['imageUrl'] != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  resolution['imageUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (resolution['notes'] != null && resolution['notes'].toString().isNotEmpty) ...[
              const Text(
                "Resolution Notes:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(resolution['notes']),
              const SizedBox(height: 12),
            ],
            Text(
              "Resolved on: ${_formatTimestamp(resolution['resolvedAt'])}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActions(Map<String, dynamic> data) {
    final currentStatus = data['status'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (currentStatus == 'reported' || currentStatus == 'assigned') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Mark as In Progress"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _updateStatus('in-progress'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text("Reject Issue", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _showRejectDialog(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Resolution Evidence",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            const SizedBox(height: 12),

            // Resolution Image
            if (_resolutionImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _resolutionImage!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _resolutionImage = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                      onPressed: () => _pickResolutionImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Gallery"),
                      onPressed: () => _pickResolutionImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Resolution Notes
            TextField(
              controller: _resolutionNotesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Resolution Notes (Optional)",
                border: OutlineInputBorder(),
                hintText: "Describe the actions taken to resolve the issue...",
              ),
            ),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: _isSubmittingResolution
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.check_circle),
                label: const Text("Mark as Resolved"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: _isSubmittingResolution ? null : _submitResolution,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= ACTIONS ================= */

  Future<void> _pickResolutionImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _resolutionImage = File(image.path);
      });
    }
  }

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

      Get.snackbar("Success", "Status updated to $newStatus");
    } catch (e) {
      Get.snackbar("Error", "Failed to update status: ${e.toString()}");
    }
  }

  Future<void> _showRejectDialog() async {
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Issue"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please provide a reason for rejection:"),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Reason for rejection...",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('issues')
            .doc(widget.issueId)
            .update({
          'status': 'rejected',
          'rejectionReason': reasonController.text.trim(),
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
        });

        Get.snackbar("Success", "Issue rejected");
      } catch (e) {
        Get.snackbar("Error", "Failed to reject issue: ${e.toString()}");
      }
    }
  }

  // Future<void> _submitResolution() async {
  //   if (_resolutionImage == null) {
  //     Get.snackbar("Error", "Please add a resolution photo");
  //     return;
  //   }
  //
  //   setState(() {
  //     _isSubmittingResolution = true;
  //   });
  //
  //   try {
  //     // Upload resolution image
  //     final mediaUrls = await MediaUploadService.upload(
  //       image: _resolutionImage,
  //       audio: null,
  //     );
  //
  //     final currentUser = FirebaseAuth.instance.currentUser;
  //
  //     // Update issue with resolution
  //     await FirebaseFirestore.instance
  //         .collection('issues')
  //         .doc(widget.issueId)
  //         .update({
  //       'status': 'resolved',
  //       'resolution': {
  //         'imageUrl': mediaUrls['imageUrl'],
  //         'notes': _resolutionNotesController.text.trim(),
  //         'resolvedAt': FieldValue.serverTimestamp(),
  //         'resolvedBy': currentUser?.uid,
  //       },
  //       'resolvedAt': FieldValue.serverTimestamp(),
  //     });
  //
  //     Get.snackbar("Success", "Issue marked as resolved");
  //     Navigator.pop(context);
  //   } catch (e) {
  //     Get.snackbar("Error", "Failed to submit resolution: ${e.toString()}");
  //   } finally {
  //     setState(() {
  //       _isSubmittingResolution = false;
  //     });
  //   }
  // }

  Future<void> _submitResolution() async {
    if (_resolutionImage == null) {
      Get.snackbar("Error", "Please add a resolution photo");
      return;
    }

    setState(() {
      _isSubmittingResolution = true;
    });

    try {
      // Upload resolution image to Firebase Storage
      final resolutionImageUrl = await FirebaseStorageService.uploadResolutionImage(
        issueId: widget.issueId,
        image: _resolutionImage!,
      );

      final currentUser = FirebaseAuth.instance.currentUser;

      // Update issue with resolution
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .update({
        'status': 'resolved',
        'resolution': {
          'imageUrl': resolutionImageUrl,
          'notes': _resolutionNotesController.text.trim(),
          'resolvedAt': FieldValue.serverTimestamp(),
          'resolvedBy': currentUser?.uid,
        },
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar("Success", "Issue marked as resolved");
      Navigator.pop(context);
    } catch (e) {
      Get.snackbar("Error", "Failed to submit resolution: ${e.toString()}");
    } finally {
      setState(() {
        _isSubmittingResolution = false;
      });
    }
  }

  /* ================= HELPERS ================= */

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      final DateTime dateTime = (timestamp as Timestamp).toDate();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}