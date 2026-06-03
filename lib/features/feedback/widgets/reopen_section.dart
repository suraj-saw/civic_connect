import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/feedback_controller.dart';

class ReopenSection extends StatelessWidget {
  final FeedbackController ctrl;
  const ReopenSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () =>
          ctrl.reopenSucceeded.value ? _successBanner(context) : _form(context),
    );
  }

  Widget _successBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.recycling_rounded, color: Colors.orange, size: 24),
          SizedBox(width: 12),
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
                  'Your proof has been submitted. The department must resolve this again.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
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
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'At least one photo and a description are required.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                _sectionLabel(
                  'Photos',
                  Icons.camera_alt_outlined,
                  required: true,
                ),
                const SizedBox(height: 8),
                _photoSection(),
                const SizedBox(height: 16),
                _sectionLabel(
                  'Video',
                  Icons.videocam_outlined,
                  required: false,
                ),
                const SizedBox(height: 8),
                _videoSection(),
                const SizedBox(height: 16),
                _sectionLabel(
                  'Voice Note',
                  Icons.mic_outlined,
                  required: false,
                ),
                const SizedBox(height: 8),
                _audioSection(),
                const SizedBox(height: 16),
                _sectionLabel(
                  'Description',
                  Icons.edit_outlined,
                  required: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => ctrl.reopenDescription.value = v,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'e.g. Pothole was only partially filled...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          ctrl.isReopening.value ? null : ctrl.submitReopen,
                      icon:
                          ctrl.isReopening.value
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.recycling_rounded, size: 18),
                      label: Text(
                        ctrl.isReopening.value
                            ? 'Submitting...'
                            : 'Reopen Issue',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon, {required bool required}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.red.shade700),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else
          Text(
            '  (optional)',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
      ],
    );
  }

  Widget _photoSection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ctrl.reopenImages.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ctrl.reopenImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder:
                  (_, i) => Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(ctrl.reopenImages[i].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => ctrl.removeReopenPhoto(i),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: ctrl.takeReopenPhoto,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(
              ctrl.reopenImages.isEmpty ? 'Take Photo' : 'Add Another Photo',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (ctrl.reopenImages.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                'At least 1 photo required',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Widget _videoSection() {
    return Obx(() {
      final video = ctrl.reopenVideo.value;
      if (video != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.videocam, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Video recorded', style: TextStyle(fontSize: 13)),
              ),
              GestureDetector(
                onTap: () => ctrl.reopenVideo.value = null,
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }
      return OutlinedButton.icon(
        onPressed: () {}, // ctrl.recordReopenVideo
        icon: const Icon(Icons.videocam_outlined, size: 18),
        label: const Text('Record Video'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade300),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }

  Widget _audioSection() {
    return Obx(() {
      final audio = ctrl.reopenAudio.value;
      if (audio != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.mic, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Voice note recorded',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              GestureDetector(
                onTap: () => ctrl.reopenAudio.value = null,
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }
      final isRecording = ctrl.isRecording.value;
      return OutlinedButton.icon(
        onPressed: () {}, // ctrl.toggleReopenRecording
        icon: Icon(
          isRecording ? Icons.stop_circle_outlined : Icons.mic_outlined,
          size: 18,
        ),
        label: Text(isRecording ? 'Stop Recording' : 'Record Voice Note'),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isRecording ? Colors.red.shade900 : Colors.red.shade700,
          backgroundColor: isRecording ? Colors.red.shade100 : null,
          side: BorderSide(color: Colors.red.shade300),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }
}
