import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/services/media_service.dart';
import '../../../data/services/storage_service.dart';
import '../controllers/issue_category_controller.dart';
import '../widgets/admin_issue_detail_section.dart';

class IssueDetailAdminPage extends StatelessWidget {
  final String issueId;
  final String adminDept;
  final String adminEmail;

  const IssueDetailAdminPage({super.key, required this.issueId, required this.adminDept, required this.adminEmail});

  @override
  Widget build(BuildContext context) {
    final categoryCtrl = Get.isRegistered<IssueCategoryController>()
        ? Get.find<IssueCategoryController>()
        : Get.put(IssueCategoryController());

    return Scaffold(
      appBar: AppBar(title: const Text('Issue Details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('issues').doc(issueId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final doc = snapshot.data;
          if (doc == null || !doc.exists || doc.data() == null) return const Center(child: Text('Issue not found'));

          final data = doc.data()!;
          final status = data['status']?.toString() ?? '';
          final isClosedStatus = status == 'resolved' || status == 'rejected';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                AdminIssueHeaderSection(data: data).animate().fadeIn(duration: 350.ms),
                AdminIssueLocationSection(data: data, onOpenMap: _openMap).animate().fadeIn(delay: 80.ms),
                AdminIssueMediaSection(data: data).animate().fadeIn(delay: 120.ms),
                if (status == 'resolved') _ResolutionProofSection(data: data).animate().fadeIn(delay: 160.ms),
                if (!isClosedStatus) ...[
                  _ActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Add Status Update',
                    onTap: () => _showAddUpdateDialog(context, status),
                  ).animate().fadeIn(delay: 160.ms),
                  _ActionButton(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Reassign Issue',
                    outlined: true,
                    onTap: () => _showReassignDialog(context, data['assignedToDept']?.toString() ?? 'unassigned', categoryCtrl),
                  ).animate().fadeIn(delay: 200.ms),
                ],
                AdminIssueTimelineSection(data: data).animate().fadeIn(delay: 240.ms),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddUpdateDialog(BuildContext context, String currentStatus) {
    String selectedStatus = 'in-progress';
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Status Update'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: selectedStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'in-progress', child: Text('In Progress')),
              DropdownMenuItem(value: 'resolved', child: Text('Resolved (requires proof)')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
            onChanged: (v) => selectedStatus = v ?? selectedStatus,
          ),
          const SizedBox(height: 12),
          TextField(controller: msgCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Next'),
            onPressed: () {
              final msg = msgCtrl.text.trim();
              if (msg.isEmpty) { AppSnackbar.show('Required', 'Please enter a message.', snackPosition: SnackPosition.BOTTOM); return; }
              Navigator.pop(context);
              if (selectedStatus == 'resolved') {
                _showResolveBottomSheet(context, msg);
              } else {
                _submitStatusUpdate(status: selectedStatus, message: msg);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showResolveBottomSheet(BuildContext context, String notes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ResolveProofSheet(issueId: issueId, adminEmail: adminEmail, notes: notes),
    );
  }

  Future<void> _submitStatusUpdate({required String status, required String message}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('issues').doc(issueId).update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'timeline': FieldValue.arrayUnion([{
          'status': status, 'message': message,
          'updatedBy': uid, 'updatedByEmail': adminEmail, 'timestamp': Timestamp.now(),
        }]),
      });
      AppSnackbar.show('Updated', 'Status updated successfully.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      AppSnackbar.show('Error', 'Failed to update: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showReassignDialog(BuildContext context, String fromDept, IssueCategoryController categoryCtrl) {
    String selectedDept = fromDept;
    final reasonCtrl = TextEditingController();
    if (categoryCtrl.categories.isEmpty) categoryCtrl.fetchCategories();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reassign Issue'),
        content: Obx(() {
          final cats = categoryCtrl.categories;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: cats.any((c) => c.id == selectedDept) ? selectedDept : (cats.isNotEmpty ? cats.first.id : null),
              decoration: const InputDecoration(labelText: 'New Department'),
              items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => selectedDept = v ?? selectedDept,
            ),
            const SizedBox(height: 12),
            TextField(controller: reasonCtrl, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder())),
          ]);
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Reassign'),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) { AppSnackbar.show('Required', 'Please enter a reason.', snackPosition: SnackPosition.BOTTOM); return; }
              Navigator.pop(context);
              await _submitReassign(selectedDept, reasonCtrl.text.trim(), fromDept);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitReassign(String toDept, String reason, String fromDept) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final issueRef = FirebaseFirestore.instance.collection('issues').doc(issueId);
    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        txn.update(issueRef, {
          'assignedToDept': toDept,
          'lastReassignedAt': FieldValue.serverTimestamp(),
          'timeline': FieldValue.arrayUnion([{
            'status': 'reassigned',
            'message': 'Reassigned from ${fromDept.toUpperCase()} to ${toDept.toUpperCase()}. Reason: $reason',
            'updatedBy': uid, 'updatedByEmail': adminEmail, 'timestamp': Timestamp.now(),
          }]),
        });
        txn.set(issueRef.collection('reassignments').doc(), {
          'fromDept': fromDept, 'toDept': toDept, 'reason': reason,
          'reassignedByUid': uid, 'reassignedByEmail': adminEmail, 'reassignedAt': FieldValue.serverTimestamp(),
        });
      });
      AppSnackbar.show('Success', 'Issue reassigned to ${toDept.toUpperCase()}.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      AppSnackbar.show('Error', 'Failed to reassign: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: outlined
            ? OutlinedButton.icon(icon: Icon(icon), label: Text(label), onPressed: onTap)
            : ElevatedButton.icon(icon: Icon(icon), label: Text(label), onPressed: onTap),
      ),
    );
  }
}

class _ResolutionProofSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ResolutionProofSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final resolution = data['resolution'] as Map<String, dynamic>?;
    if (resolution == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrls = (resolution['proofImageUrls'] as List<dynamic>? ?? []).whereType<String>().toList();
    final notes = resolution['notes'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.tertiary.withValues(alpha: isDark ? 0.16 : 0.07),
          cs.surface,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.tertiary.withValues(alpha: isDark ? 0.38 : 0.26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.verified_rounded, color: cs.tertiary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Resolution Proof',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: cs.onSurface,
              ),
            ),
          ]),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              notes,
              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface),
            ),
          ],
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal, itemCount: imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[i],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
                    errorWidget: (_, __, ___) => Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.broken_image_outlined, size: 18, color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolveProofSheet extends StatefulWidget {
  final String issueId;
  final String adminEmail;
  final String notes;
  const _ResolveProofSheet({required this.issueId, required this.adminEmail, required this.notes});

  @override
  State<_ResolveProofSheet> createState() => _ResolveProofSheetState();
}

class _ResolveProofSheetState extends State<_ResolveProofSheet> {
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  File? _video;
  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) setState(() => _images.addAll(picked.take(5 - _images.length)));
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null && _images.length < 5) setState(() => _images.add(picked));
  }

  Future<void> _recordVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.camera);
    if (picked != null) setState(() => _video = File(picked.path));
  }

  Future<void> _submit() async {
    if (_images.isEmpty) {
      AppSnackbar.show('Photo Required', 'Please attach at least one photo.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Compress images in parallel
      final rawImages = _images.map((x) => File(x.path)).toList();
      final compressedImages = await Future.wait(
          rawImages.map((f) => MediaService.compressImage(f)));

      // Upload all media in parallel
      final media = await StorageService.uploadResolutionMedia(
        issueId: widget.issueId,
        images: compressedImages,
        video: _video,
      );

      // Single Firestore update
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .update({
        'status': 'resolved',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'resolution': {
          'proofImageUrls': media['photoUrls'],
          'proofVideoUrl': media['videoUrl'],
          'notes': widget.notes,
          'resolvedAt': Timestamp.now(),
        },
        'timeline': FieldValue.arrayUnion([{
          'status': 'resolved',
          'message': widget.notes,
          'updatedBy': uid,
          'updatedByEmail': widget.adminEmail,
          'timestamp': Timestamp.now(),
        }]),
      });

      if (mounted) Navigator.pop(context);
      AppSnackbar.show('Resolved', 'Issue marked as resolved.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      AppSnackbar.show('Error', 'Failed to submit resolution: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  cs.tertiary.withValues(alpha: isDark ? 0.22 : 0.12),
                  cs.surface,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline, color: cs.tertiary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit Resolution Proof',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'At least one photo is required.',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const Divider(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.34 : 0.62),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(widget.notes, style: TextStyle(fontSize: 14, color: cs.onSurface)),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Text('Photos', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(' *', style: GoogleFonts.inter(color: cs.error, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${_images.length}/5', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
          const SizedBox(height: 10),
          if (_images.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemCount: _images.length,
              itemBuilder: (_, i) => Stack(fit: StackFit.expand, children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_images[i].path), fit: BoxFit.cover)),
                Positioned(top: 4, right: 4, child: GestureDetector(
                  onTap: () => setState(() => _images.removeAt(i)),
                  child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(3), child: const Icon(Icons.close, size: 13, color: Colors.white)),
                )),
              ]),
            ),
            const SizedBox(height: 8),
          ],
          Row(children: [
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.camera_alt_outlined, size: 17), label: const Text('Camera'),
                onPressed: _images.length < 5 ? _takePhoto : null)),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.photo_outlined, size: 17), label: const Text('Gallery'),
                onPressed: _images.length < 5 ? _pickImages : null)),
          ]),
          const SizedBox(height: 20),
          Text('Video (optional)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          if (_video != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  cs.secondary.withValues(alpha: isDark ? 0.18 : 0.1),
                  cs.surface,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.secondary.withValues(alpha: isDark ? 0.42 : 0.24),
                ),
              ),
              child: Row(children: [
                Icon(Icons.videocam, color: cs.secondary, size: 20), const SizedBox(width: 8),
                Expanded(child: Text('Video recorded', style: TextStyle(fontSize: 13, color: cs.onSurface))),
                GestureDetector(onTap: () => setState(() => _video = null), child: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant)),
              ]),
            )
          else
            SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: const Icon(Icons.videocam_outlined, size: 17),
                label: const Text('Record Video'), onPressed: _recordVideo)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(_isSubmitting ? 'Uploading...' : 'Submit Resolution'),
            ),
          ),
        ]),
      ),
    );
  }
}
