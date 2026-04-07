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
import '../../../core/widgets/app_snackbar.dart';
import '../models/citizen_model_feedback.dart';

class FeedbackController extends GetxController {
  final String issueId;
  FeedbackController({required this.issueId});

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();

  final isCheckingExisting = true.obs;
  final isSubmitting = false.obs;
  final alreadySubmitted = false.obs;
  final existingFeedback = Rxn<CitizenFeedbackModel>();

  final overallRating     = 3.obs;
  final workQualityScore  = 3.obs;
  final timelinessScore   = 3.obs;
  final issueActuallyFixed = true.obs;
  final comments = ''.obs;

  final isReopening    = false.obs;
  final reopenSucceeded = false.obs;
  final reopenDescription = ''.obs;
  final reopenImages = <XFile>[].obs;
  final reopenVideo  = Rxn<File>();
  final reopenAudio  = Rxn<File>();
  final isRecording  = false.obs;

  StreamSubscription<DocumentSnapshot>? _statusSub;

  String get _docId => (_auth.currentUser?.email ?? 'unknown').replaceAll('.', '_');

  @override
  void onInit() { super.onInit(); _checkExistingFeedback(); _listenToIssueStatus(); }

  @override
  void onClose() { if (isRecording.value) _recorder.stop(); _recorder.dispose(); _statusSub?.cancel(); super.onClose(); }

  void _listenToIssueStatus() {
    _statusSub = _firestore.collection('issues').doc(issueId).snapshots().listen((snap) {
      if (!snap.exists) return;
      final status = snap.data()?['status']?.toString();
      if (status == 'resolved' && reopenSucceeded.value) _resetFeedbackState();
    });
  }

  void _resetFeedbackState() {
    alreadySubmitted.value = false; existingFeedback.value = null; reopenSucceeded.value = false;
    reopenDescription.value = ''; reopenImages.clear(); reopenVideo.value = null; reopenAudio.value = null;
    overallRating.value = 3; workQualityScore.value = 3; timelinessScore.value = 3;
    issueActuallyFixed.value = true; comments.value = ''; isCheckingExisting.value = false;
  }

  Future<void> _checkExistingFeedback() async {
    try {
      final issueDoc = await _firestore.collection('issues').doc(issueId).get();
      final status = issueDoc.data()?['status']?.toString();
      final feedbackDoc = await _firestore.collection('issues').doc(issueId).collection('feedback').doc(_docId).get();
      if (feedbackDoc.exists && feedbackDoc.data() != null) {
        if (status == 'reopened') {
          existingFeedback.value = CitizenFeedbackModel.fromMap(feedbackDoc.data()!);
          alreadySubmitted.value = true; reopenSucceeded.value = true;
        } else {
          existingFeedback.value = CitizenFeedbackModel.fromMap(feedbackDoc.data()!);
          alreadySubmitted.value = true;
        }
      }
    } catch (e) { debugPrint('[Feedback] Check error: $e'); } finally { isCheckingExisting.value = false; }
  }

  Future<void> submit() async {
    if (comments.value.trim().isEmpty) { AppSnackbar.show('Required', 'Please write a comment before submitting.', snackPosition: SnackPosition.BOTTOM); return; }
    final email = _auth.currentUser?.email;
    if (email == null) return;
    isSubmitting.value = true;
    try {
      final feedback = CitizenFeedbackModel(issueId: issueId, citizenEmail: email,
          overallRating: overallRating.value, workQualityScore: workQualityScore.value,
          timelinessScore: timelinessScore.value, issueActuallyFixed: issueActuallyFixed.value,
          comments: comments.value.trim(), submittedAt: DateTime.now());
      await _firestore.collection('issues').doc(issueId).collection('feedback').doc(_docId).set(feedback.toMap());
      await _firestore.collection('issues').doc(issueId).update({'citizenFeedbackSubmitted': true, 'citizenOverallRating': overallRating.value, 'citizenReportedFixed': issueActuallyFixed.value});
      existingFeedback.value = feedback; alreadySubmitted.value = true;
      if (issueActuallyFixed.value) AppSnackbar.show('Thank you!', 'Your feedback holds authorities accountable.', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
    } catch (e) { debugPrint('[Feedback] Submit error: $e'); AppSnackbar.show('Error', 'Could not submit feedback. Please try again.', snackPosition: SnackPosition.BOTTOM);
    } finally { isSubmitting.value = false; }
  }

  Future<void> takeReopenPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) reopenImages.add(picked);
  }

  void removeReopenPhoto(int index) => reopenImages.removeAt(index);

  Future<void> submitReopen() async {
    if (reopenImages.isEmpty) { AppSnackbar.show('Photo Required', 'Please attach at least 1 photo.', snackPosition: SnackPosition.BOTTOM); return; }
    if (reopenDescription.value.trim().isEmpty) { AppSnackbar.show('Required', 'Please enter a description.', snackPosition: SnackPosition.BOTTOM); return; }
    final email = _auth.currentUser?.email;
    if (email == null) return;
    isReopening.value = true;
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final base = 'reopen/$issueId';
      final photoUrls = await Future.wait(reopenImages.map((img) async {
        final ref = FirebaseStorage.instance.ref().child('$base/img_${ts}_${reopenImages.indexOf(img)}.jpg');
        await ref.putFile(File(img.path));
        return ref.getDownloadURL();
      }));
      final batch = _firestore.batch();
      final issueRef = _firestore.collection('issues').doc(issueId);
      batch.update(issueRef, {
        'status': 'reopened', 'statusUpdatedAt': FieldValue.serverTimestamp(),
        'reopenedAt': FieldValue.serverTimestamp(), 'reopenedBy': email,
        'reopenProofImageUrls': photoUrls, 'citizenFeedbackSubmitted': false,
        'citizenReportedFixed': null, 'citizenOverallRating': null,
        'timeline': FieldValue.arrayUnion([{'status': 'reopened', 'message': reopenDescription.value.trim(), 'updatedBy': email, 'updatedByEmail': email, 'proofImageUrls': photoUrls, 'timestamp': Timestamp.now()}]),
      });
      final feedbackRef = issueRef.collection('feedback').doc(_docId);
      batch.delete(feedbackRef);
      await batch.commit();
      reopenSucceeded.value = true;
      AppSnackbar.show('Issue Reopened', 'Your proof has been submitted. The department must resolve this again.', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4), backgroundColor: Colors.orange.shade100);
    } catch (e) { debugPrint('[Reopen] Error: $e'); AppSnackbar.show('Error', 'Could not reopen the issue. Please try again.', snackPosition: SnackPosition.BOTTOM);
    } finally { isReopening.value = false; }
  }
}
