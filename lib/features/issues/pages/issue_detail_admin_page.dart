import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/issue_category_controller.dart';
import '../widgets/admin_issue_detail_section.dart';
import 'reassignment_timeline_page.dart';

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
    final categoryController = Get.isRegistered<IssueCategoryController>()
        ? Get.find<IssueCategoryController>()
        : Get.put(IssueCategoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () =>
                Get.to(() => ReassignmentTimelinePage(issueId: issueId)),
            tooltip: 'Reassignment History',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .doc(issueId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snapshot.data;
          if (doc == null || !doc.exists || doc.data() == null) {
            return const Center(child: Text('Issue not found'));
          }
          final data = doc.data()!;
          final status = data['status']?.toString() ?? '';
          final isClosedStatus =
              status == 'resolved' || status == 'rejected';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                AdminIssueHeaderSection(data: data),
                AdminIssueLocationSection(
                    data: data, onOpenMap: _openMap),
                AdminIssueMediaSection(data: data),
                // Resolution proof section (shown after resolved)
                if (status == 'resolved')
                  _ResolutionProofSection(data: data),
                if (!isClosedStatus) ...[
                  _buildAddUpdateButton(context, status),
                  _buildReassignButton(context, data, categoryController),
                ],
                AdminIssueTimelineSection(data: data),
              ],
            ),
          );
        },
      ),
    );
  }

  /* ── Buttons ─────────────────────────────────────────────────── */

  Widget _buildAddUpdateButton(BuildContext context, String currentStatus) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Status Update'),
          onPressed: () => _showAddUpdateDialog(context, currentStatus),
        ),
      ),
    );
  }

  Widget _buildReassignButton(
      BuildContext context,
      Map<String, dynamic> data,
      IssueCategoryController categoryController,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Reassign Issue'),
          onPressed: () => _showReassignDialog(
            context,
            data['assignedToDept']?.toString() ?? 'unassigned',
            categoryController,
          ),
        ),
      ),
    );
  }

  /* ── Status update dialog (non-resolve statuses) ─────────────── */

  void _showAddUpdateDialog(BuildContext context, String currentStatus) {
    // When admin picks "resolved", open the dedicated resolve bottom sheet
    // which requires proof media.
    String selectedStatus = 'in_progress';
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Status Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(
                    value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(
                    value: 'resolved',
                    child: Text('Resolved (requires proof)')),
                DropdownMenuItem(
                    value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (v) => selectedStatus = v ?? selectedStatus,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Next'),
            onPressed: () {
              final message = messageCtrl.text.trim();
              if (message.isEmpty) {
                Get.snackbar('Required', 'Please enter a message.',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              Navigator.pop(context);
              if (selectedStatus == 'resolved') {
                _showResolveBottomSheet(context, message);
              } else {
                _submitStatusUpdate(
                    status: selectedStatus, message: message);
              }
            },
          ),
        ],
      ),
    );
  }

  /* ── Resolve bottom sheet — requires proof media ─────────────── */

  void _showResolveBottomSheet(BuildContext context, String notes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ResolveProofSheet(
        issueId: issueId,
        adminEmail: adminEmail,
        notes: notes,
      ),
    );
  }

  /* ── Plain status update (non-resolve) ───────────────────────── */

  Future<void> _submitStatusUpdate({
    required String status,
    required String message,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': uid,
        'timeline': FieldValue.arrayUnion([
          {
            'status': status,
            'message': message,
            'updatedBy': uid,
            'updatedByEmail': adminEmail,
            'timestamp': Timestamp.now(),
          }
        ]),
      });
      Get.snackbar('Updated', 'Status updated successfully.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /* ── Reassign dialog ─────────────────────────────────────────── */

  void _showReassignDialog(
      BuildContext context,
      String fromDept,
      IssueCategoryController categoryController,
      ) {
    String selectedDept = fromDept;
    final reasonCtrl = TextEditingController();

    if (categoryController.categories.isEmpty) {
      categoryController.fetchCategories();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reassign Issue'),
        content: Obx(() {
          final categories = categoryController.categories;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: categories.any((c) => c.id == selectedDept)
                    ? selectedDept
                    : (categories.isNotEmpty ? categories.first.id : null),
                decoration:
                const InputDecoration(labelText: 'New Department'),
                items: categories
                    .map((cat) => DropdownMenuItem(
                    value: cat.id, child: Text(cat.name)))
                    .toList(),
                onChanged: (v) => selectedDept = v ?? selectedDept,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Reassign'),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) {
                Get.snackbar('Required', 'Please enter a reason.',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              Navigator.pop(context);
              await _submitReassign(
                  selectedDept, reasonCtrl.text.trim(), fromDept);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitReassign(
      String toDept, String reason, String fromDept) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final issueRef =
    FirebaseFirestore.instance.collection('issues').doc(issueId);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        txn.update(issueRef, {
          'assignedToDept': toDept,
          'lastReassignedAt': FieldValue.serverTimestamp(),
          'timeline': FieldValue.arrayUnion([
            {
              'status': 'reassigned',
              'message': 'Reassigned from ${fromDept.toUpperCase()} to '
                  '${toDept.toUpperCase()}. Reason: $reason',
              'updatedBy': uid,
              'updatedByEmail': adminEmail,
              'timestamp': Timestamp.now(),
            }
          ]),
        });
        txn.set(issueRef.collection('reassignments').doc(), {
          'fromDept': fromDept,
          'toDept': toDept,
          'reason': reason,
          'reassignedByUid': uid,
          'reassignedByEmail': adminEmail,
          'reassignedAt': FieldValue.serverTimestamp(),
        });
      });
      Get.snackbar(
          'Success', 'Issue reassigned to ${toDept.toUpperCase()}.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to reassign: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/* ═══════════════════════════════════════════════════════════════════
   Resolution proof bottom sheet (StatefulWidget — owns local state)
═══════════════════════════════════════════════════════════════════ */

class _ResolveProofSheet extends StatefulWidget {
  final String issueId;
  final String adminEmail;
  final String notes;

  const _ResolveProofSheet({
    required this.issueId,
    required this.adminEmail,
    required this.notes,
  });

  @override
  State<_ResolveProofSheet> createState() => _ResolveProofSheetState();
}

class _ResolveProofSheetState extends State<_ResolveProofSheet> {
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  File? _video;
  bool _isSubmitting = false;

  /* ── Media pickers ───────────────────────────────────────────── */

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        // cap total at 5
        _images.addAll(picked.take(5 - _images.length));
      });
    }
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 80);
    if (picked != null && _images.length < 5) {
      setState(() => _images.add(picked));
    }
  }

  Future<void> _recordVideo() async {
    final picked =
    await _picker.pickVideo(source: ImageSource.camera);
    if (picked != null) setState(() => _video = File(picked.path));
  }

  void _removeImage(int i) => setState(() => _images.removeAt(i));
  void _removeVideo() => setState(() => _video = null);

  /* ── Validation ──────────────────────────────────────────────── */

  bool get _hasEnoughMedia => _images.isNotEmpty;

  /* ── Submit ──────────────────────────────────────────────────── */

  Future<void> _submit() async {
    if (!_hasEnoughMedia) {
      Get.snackbar(
        'Photo Required',
        'Please attach at least one photo as resolution proof.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final base =
          'issues/${widget.issueId}/resolution_proof';
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Upload images
      final List<String> imageUrls = [];
      for (int i = 0; i < _images.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('$base/photo_${ts}_$i.jpg');
        final task = await ref.putFile(File(_images[i].path));
        imageUrls.add(await task.ref.getDownloadURL());
      }

      // Upload video (optional)
      String? videoUrl;
      if (_video != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('$base/video_$ts.mp4');
        final task = await ref.putFile(_video!);
        videoUrl = await task.ref.getDownloadURL();
      }

      // Firestore update
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .update({
        'status': 'resolved',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': uid,
        'resolution': {
          'notes': widget.notes,
          'proofImageUrls': imageUrls,
          'proofVideoUrl': videoUrl,
          'resolvedAt': Timestamp.now(),
          'resolvedBy': uid,
          'resolvedByEmail': widget.adminEmail,
        },
        'resolvedAt': FieldValue.serverTimestamp(),
        'timeline': FieldValue.arrayUnion([
          {
            'status': 'resolved',
            'message': widget.notes,
            'proofImageUrls': imageUrls,
            'proofVideoUrl': videoUrl,
            'updatedBy': uid,
            'updatedByEmail': widget.adminEmail,
            'timestamp': Timestamp.now(),
          }
        ]),
      });

      if (mounted) Navigator.pop(context);
      Get.snackbar('Resolved', 'Issue marked as resolved with proof.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100);
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit resolution: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /* ── Build ───────────────────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_outline,
                      color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submit Resolution Proof',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text(
                        'At least one photo is required.',
                        style:
                        TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Notes preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(widget.notes,
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Photos section
            _SectionLabel(
              icon: Icons.photo_library_outlined,
              label: 'Photos',
              required: true,
              trailing: '${_images.length}/5',
            ),
            const SizedBox(height: 10),
            if (_images.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: _images.length,
                itemBuilder: (_, i) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_images[i].path),
                          fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(i),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Camera'),
                    onPressed: _images.length < 5 ? _takePhoto : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_outlined, size: 18),
                    label: const Text('Gallery'),
                    onPressed: _images.length < 5 ? _pickImages : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Video section
            _SectionLabel(
              icon: Icons.videocam_outlined,
              label: 'Video',
              required: false,
            ),
            const SizedBox(height: 10),
            if (_video != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.videocam,
                        color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                        child: Text('Video recorded',
                            style: TextStyle(fontSize: 13))),
                    GestureDetector(
                      onTap: _removeVideo,
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            if (_video == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.videocam_outlined, size: 18),
                  label: const Text('Record Video'),
                  onPressed: _recordVideo,
                ),
              ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isSubmitting
                    ? 'Submitting...'
                    : 'Mark as Resolved'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ═══════════════════════════════════════════════════════════════════
   Resolution proof display (shown on detail page after resolved)
═══════════════════════════════════════════════════════════════════ */

class _ResolutionProofSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ResolutionProofSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final resolution = data['resolution'] as Map<String, dynamic>?;
    if (resolution == null) return const SizedBox.shrink();

    final imageUrls = (resolution['proofImageUrls'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final videoUrl = resolution['proofVideoUrl'] as String?;
    final notes = resolution['notes'] as String?;

    if (imageUrls.isEmpty && videoUrl == null && (notes?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_rounded,
                    color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Text('Resolution Proof',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green.shade800)),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(notes, style: const TextStyle(fontSize: 13)),
            ],
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrls[i],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
            if (videoUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.videocam,
                      color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 6),
                  const Text('Resolution video attached',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* ── Shared label widget ─────────────────────────────────────────── */

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool required;
  final String? trailing;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.required,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        if (required) ...[
          const SizedBox(width: 4),
          Text('*',
              style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.bold)),
        ] else
          Text('  (optional)',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500)),
        if (trailing != null) ...[
          const Spacer(),
          Text(trailing!,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500)),
        ],
      ],
    );
  }
}