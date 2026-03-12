import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/citizen_model_feedback.dart';

class FeedbackController extends GetxController {
  final String issueId;

  FeedbackController({required this.issueId});

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();

  // ── Feedback state ─────────────────────────────────────────────
  final isCheckingExisting = true.obs;
  final isSubmitting = false.obs;
  final alreadySubmitted = false.obs;
  final existingFeedback = Rxn<CitizenFeedbackModel>();

  // ── Feedback form values ───────────────────────────────────────
  final overallRating = 3.obs;
  final workQualityScore = 3.obs;
  final timelinessScore = 3.obs;
  final issueActuallyFixed = true.obs;
  final comments = ''.obs;

  // ── Reopen state ───────────────────────────────────────────────
  final isReopening = false.obs;
  final reopenSucceeded = false.obs;
  final reopenDescription = ''.obs;
  final reopenImages = <XFile>[].obs;
  final reopenVideo = Rxn<File>();
  final reopenAudio = Rxn<File>();
  final isRecording = false.obs;

  StreamSubscription<DocumentSnapshot>? _issueStatusSubscription;

  String get _docId =>
      (_auth.currentUser?.email ?? 'unknown').replaceAll('.', '_');

  @override
  void onInit() {
    super.onInit();
    _checkExistingFeedback();
    _listenToIssueStatus();
  }

  @override
  void onClose() {
    if (isRecording.value) _recorder.stop();
    _recorder.dispose();
    _issueStatusSubscription?.cancel();
    super.onClose();
  }

  // ── Listen to issue status changes ────────────────────────────
  // When admin re-resolves after a reopen, we detect the status
  // change to 'resolved' and reset feedback state so the citizen
  // can submit fresh feedback.
  void _listenToIssueStatus() {
    _issueStatusSubscription = _firestore
        .collection('issues')
        .doc(issueId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final status = snapshot.data()?['status']?.toString();

      // If issue just became resolved again after a reopen,
      // and the citizen had already reopened (reopenSucceeded),
      // reset everything so a fresh feedback form is shown.
      if (status == 'resolved' && reopenSucceeded.value) {
        _resetFeedbackState();
      }
    });
  }

  void _resetFeedbackState() {
    alreadySubmitted.value = false;
    existingFeedback.value = null;
    reopenSucceeded.value = false;
    reopenDescription.value = '';
    reopenImages.clear();
    reopenVideo.value = null;
    reopenAudio.value = null;
    overallRating.value = 3;
    workQualityScore.value = 3;
    timelinessScore.value = 3;
    issueActuallyFixed.value = true;
    comments.value = '';
    isCheckingExisting.value = false;
  }

  // ── Check existing feedback ────────────────────────────────────
  Future<void> _checkExistingFeedback() async {
    try {
      final issueDoc =
      await _firestore.collection('issues').doc(issueId).get();
      final status = issueDoc.data()?['status']?.toString();

      final feedbackDoc = await _firestore
          .collection('issues')
          .doc(issueId)
          .collection('feedback')
          .doc(_docId)
          .get();

      if (feedbackDoc.exists && feedbackDoc.data() != null) {
        // Only treat feedback as valid if the issue hasn't been
        // reopened since the feedback was submitted.
        // If status is 'resolved' (not 'reopened'), the old feedback
        // is from the previous resolution cycle — check if we need
        // to show the fresh form instead.
        if (status == 'reopened') {
          // Issue is currently reopened → citizen already acted,
          // just show the reopen-success banner.
          existingFeedback.value =
              CitizenFeedbackModel.fromMap(feedbackDoc.data()!);
          alreadySubmitted.value = true;
          reopenSucceeded.value = true;
        } else {
          // Issue is resolved — show previously submitted feedback.
          existingFeedback.value =
              CitizenFeedbackModel.fromMap(feedbackDoc.data()!);
          alreadySubmitted.value = true;
        }
      }
    } catch (e) {
      debugPrint('[Feedback] Check error: $e');
    } finally {
      isCheckingExisting.value = false;
    }
  }

  // ── Submit feedback ────────────────────────────────────────────
  Future<void> submit() async {
    if (comments.value.trim().isEmpty) {
      Get.snackbar('Required', 'Please write a comment before submitting.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final email = _auth.currentUser?.email;
    if (email == null) return;

    isSubmitting.value = true;

    try {
      final feedback = CitizenFeedbackModel(
        issueId: issueId,
        citizenEmail: email,
        overallRating: overallRating.value,
        workQualityScore: workQualityScore.value,
        timelinessScore: timelinessScore.value,
        issueActuallyFixed: issueActuallyFixed.value,
        comments: comments.value.trim(),
        submittedAt: DateTime.now(),
      );

      await _firestore
          .collection('issues')
          .doc(issueId)
          .collection('feedback')
          .doc(_docId)
          .set(feedback.toMap());

      await _firestore.collection('issues').doc(issueId).update({
        'citizenFeedbackSubmitted': true,
        'citizenOverallRating': overallRating.value,
        'citizenReportedFixed': issueActuallyFixed.value,
      });

      existingFeedback.value = feedback;
      alreadySubmitted.value = true;

      if (issueActuallyFixed.value) {
        Get.snackbar(
          'Thank you!',
          'Your feedback holds authorities accountable.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('[Feedback] Submit error: $e');
      Get.snackbar('Error', 'Could not submit feedback. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ── Reopen — photo ─────────────────────────────────────────────
  Future<void> takeReopenPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) reopenImages.add(picked);
  }

  void removeReopenPhoto(int index) {
    if (index >= 0 && index < reopenImages.length) {
      reopenImages.removeAt(index);
    }
  }

  // ── Reopen — video ─────────────────────────────────────────────
  Future<void> recordReopenVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.camera);
    if (picked != null) reopenVideo.value = File(picked.path);
  }

  void removeReopenVideo() => reopenVideo.value = null;

  // ── Reopen — audio ─────────────────────────────────────────────
  Future<void> toggleReopenAudioRecording() async {
    if (isRecording.value) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        Get.snackbar('Permission Denied',
            'Microphone permission is required to record audio.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/reopen_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      isRecording.value = true;
    } catch (e) {
      Get.snackbar('Error', 'Could not start recording.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      isRecording.value = false;
      if (path != null) {
        reopenAudio.value = File(path);
        Get.snackbar('Audio Recorded', 'Voice note added.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      isRecording.value = false;
    }
  }

  void removeReopenAudio() => reopenAudio.value = null;

  // ── Reopen — validation ────────────────────────────────────────
  bool _validateReopen() {
    if (reopenImages.isEmpty) {
      Get.snackbar('Photo Required',
          'Please take at least one photo as proof that the issue is unresolved.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3));
      return false;
    }
    if (reopenDescription.value.trim().isEmpty) {
      Get.snackbar('Description Required',
          'Please describe why the issue is not resolved.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    return true;
  }

  // ── Reopen — submit ────────────────────────────────────────────
  Future<void> submitReopen() async {
    if (!_validateReopen()) return;

    isReopening.value = true;

    try {
      final email = _auth.currentUser?.email ?? '';
      final base = 'issues/$issueId/reopen_proof';
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Upload photos
      final List<String> photoUrls = [];
      for (int i = 0; i < reopenImages.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('$base/photo_${ts}_$i.jpg');
        final task = await ref.putFile(File(reopenImages[i].path));
        photoUrls.add(await task.ref.getDownloadURL());
      }

      // Upload video
      String? videoUrl;
      if (reopenVideo.value != null) {
        final ref =
        FirebaseStorage.instance.ref().child('$base/video_$ts.mp4');
        final task = await ref.putFile(reopenVideo.value!);
        videoUrl = await task.ref.getDownloadURL();
      }

      // Upload audio
      String? audioUrl;
      if (reopenAudio.value != null) {
        final ref =
        FirebaseStorage.instance.ref().child('$base/audio_$ts.m4a');
        final task = await ref.putFile(reopenAudio.value!);
        audioUrl = await task.ref.getDownloadURL();
      }

      final batch = _firestore.batch();
      final issueRef = _firestore.collection('issues').doc(issueId);

      // Update issue status to reopened
      batch.update(issueRef, {
        'status': 'reopened',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'reopenedAt': FieldValue.serverTimestamp(),
        'reopenedBy': email,
        'reopenProofImageUrls': photoUrls,
        'reopenProofVideoUrl': videoUrl,
        'reopenProofAudioUrl': audioUrl,
        // Clear previous feedback flags so admin sees fresh state
        'citizenFeedbackSubmitted': false,
        'citizenReportedFixed': null,
        'citizenOverallRating': null,
        'timeline': FieldValue.arrayUnion([
          {
            'status': 'reopened',
            'message': reopenDescription.value.trim(),
            'updatedBy': email,
            'updatedByEmail': email,
            'proofImageUrls': photoUrls,
            'proofVideoUrl': videoUrl,
            'proofAudioUrl': audioUrl,
            'timestamp': Timestamp.now(),
          }
        ]),
      });

      // Delete stale feedback doc so a fresh form appears after
      // admin resolves again
      final feedbackRef = issueRef.collection('feedback').doc(_docId);
      batch.delete(feedbackRef);

      await batch.commit();
      reopenSucceeded.value = true;

      Get.snackbar(
        'Issue Reopened',
        'Your proof has been submitted. The department must resolve this again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange.shade100,
      );
    } catch (e) {
      debugPrint('[Reopen] Error: $e');
      Get.snackbar('Error', 'Could not reopen the issue. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isReopening.value = false;
    }
  }
}