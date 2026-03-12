import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/feedback_controller.dart';

class ReopenSection extends StatelessWidget {
  final FeedbackController ctrl;

  const ReopenSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.reopenSucceeded.value) return _buildSuccessBanner();
      return _buildForm();
    });
  }

  /* ── Success banner ───────────────────────────────────────────── */

  Widget _buildSuccessBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.recycling_rounded, color: Colors.orange, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Issue Reopened',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your proof has been submitted. '
                      'The department must resolve this again.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ── Reopen form ──────────────────────────────────────────────── */

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormHeader(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provide proof below. At least one photo and a description are required.',
                  style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),

                // ── Photos (required) ──
                _buildSectionLabel(
                    'Photos', Icons.camera_alt_outlined, required: true),
                const SizedBox(height: 8),
                _buildPhotoSection(),

                const SizedBox(height: 16),

                // ── Video (optional) ──
                _buildSectionLabel(
                    'Video', Icons.videocam_outlined, required: false),
                const SizedBox(height: 8),
                _buildVideoSection(),

                const SizedBox(height: 16),

                // ── Audio (optional) ──
                _buildSectionLabel(
                    'Voice Note', Icons.mic_outlined, required: false),
                const SizedBox(height: 8),
                _buildAudioSection(),

                const SizedBox(height: 16),

                // ── Description (required) ──
                _buildSectionLabel(
                    'Description', Icons.edit_outlined, required: true),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => ctrl.reopenDescription.value = v,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText:
                    'e.g. Pothole was only partially filled, water is still leaking...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Submit ──
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: ctrl.isReopening.value
                        ? null
                        : ctrl.submitReopen,
                    icon: ctrl.isReopening.value
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.recycling_rounded, size: 18),
                    label: Text(ctrl.isReopening.value
                        ? 'Submitting...'
                        : 'Reopen Issue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Issue Not Resolved — Submit Proof',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon,
      {required bool required}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.red.shade700),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text('*',
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold)),
        ] else
          Text(
            '  (optional)',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
      ],
    );
  }

  /* ── Photo section ────────────────────────────────────────────── */

  Widget _buildPhotoSection() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid of taken photos
          if (ctrl.reopenImages.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ctrl.reopenImages.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (_, i) => _buildPhotoThumbnail(i),
            ),

          if (ctrl.reopenImages.isNotEmpty) const SizedBox(height: 8),

          // Take photo button — always visible so citizen can add more.
          OutlinedButton.icon(
            onPressed: ctrl.takeReopenPhoto,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(ctrl.reopenImages.isEmpty
                ? 'Take Photo'
                : 'Add Another Photo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),

          // Validation hint
          if (ctrl.reopenImages.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'At least 1 photo is required',
                style: TextStyle(
                    fontSize: 11, color: Colors.red.shade400),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildPhotoThumbnail(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(ctrl.reopenImages[index].path),
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => ctrl.removeReopenPhoto(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  /* ── Video section ────────────────────────────────────────────── */

  Widget _buildVideoSection() {
    return Obx(() {
      if (ctrl.reopenVideo.value != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.videocam_rounded,
                  color: Colors.red.shade600, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Video recorded',
                    style: TextStyle(fontSize: 13)),
              ),
              GestureDetector(
                onTap: ctrl.removeReopenVideo,
                child: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 20),
              ),
            ],
          ),
        );
      }

      return OutlinedButton.icon(
        onPressed: ctrl.recordReopenVideo,
        icon: const Icon(Icons.videocam_outlined, size: 18),
        label: const Text('Record Video'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade300),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }

  /* ── Audio section ────────────────────────────────────────────── */

  Widget _buildAudioSection() {
    return Obx(() {
      if (ctrl.reopenAudio.value != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.mic_rounded,
                  color: Colors.red.shade600, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Voice note recorded',
                    style: TextStyle(fontSize: 13)),
              ),
              GestureDetector(
                onTap: ctrl.removeReopenAudio,
                child: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 20),
              ),
            ],
          ),
        );
      }

      return OutlinedButton.icon(
        onPressed: ctrl.toggleReopenAudioRecording,
        icon: Icon(
          ctrl.isRecording.value ? Icons.stop_circle_outlined : Icons.mic_outlined,
          size: 18,
        ),
        label: Text(ctrl.isRecording.value ? 'Stop Recording' : 'Record Voice Note'),
        style: OutlinedButton.styleFrom(
          foregroundColor: ctrl.isRecording.value
              ? Colors.red.shade900
              : Colors.red.shade700,
          backgroundColor: ctrl.isRecording.value
              ? Colors.red.shade100
              : null,
          side: BorderSide(color: Colors.red.shade300),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }
}