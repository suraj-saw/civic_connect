import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../core/constants/issue_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/issue_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/storage_service.dart';
import '../../home/controllers/home_citizen_controller.dart';
import '../../home/pages/home_citizen_page.dart';
import '../models/duplicate_check_result.dart';
import '../utils/duplicate_issue_detector.dart';
import '../widgets/duplicate_issue_dialog.dart';

class ReportIssueController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();

  final descriptionTextController = TextEditingController();
  final selectedImages    = RxList<XFile>();
  final selectedImagePath = Rxn<String>();
  final selectedImage     = Rx<File?>(null);
  final selectedVideo     = Rx<File?>(null);
  final selectedVideoPath = Rxn<String>();
  final selectedAudio     = Rx<File?>(null);
  final recordedAudioPath = Rxn<String>();
  final recordedAudio     = Rxn<File>();
  final isRecording     = false.obs;
  final isSubmitting    = false.obs;
  final uploadProgress  = 0.0.obs;
  final description     = ''.obs;
  final selectedCategoryId = Rxn<String>();
  final isFormDirty    = false.obs;
  final submitSuccess  = false.obs;
  final issueLocation  = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() { super.onInit(); _fetchLocationIfPermitted(); }

  Future<void> _fetchLocationIfPermitted() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted && issueLocation.value == null) await _fetchLocation();
  }

  Future<void> pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img == null) return;
    selectedImage.value = File(img.path);
    selectedImagePath.value = img.path;
    selectedImages.add(img);
    isFormDirty.value = true;
    if (issueLocation.value == null) await _fetchLocationIfPermitted();
  }

  Future<void> captureImage() => pickImage();

  void removeImage(int index) {
    selectedImages.removeAt(index);
    if (selectedImages.isEmpty) { selectedImage.value = null; selectedImagePath.value = null; }
    else { selectedImage.value = File(selectedImages.first.path); selectedImagePath.value = selectedImages.first.path; }
    isFormDirty.value = true;
  }

  void removeAllImages() { selectedImage.value = null; selectedImagePath.value = null; selectedImages.clear(); isFormDirty.value = true; }

  Future<void> captureVideo() async {
    final vid = await _picker.pickVideo(source: ImageSource.camera);
    if (vid == null) return;
    selectedVideo.value = File(vid.path);
    selectedVideoPath.value = vid.path;
    isFormDirty.value = true;
  }

  Future<void> pickVideo() => captureVideo();
  void removeVideo() { selectedVideo.value = null; selectedVideoPath.value = null; isFormDirty.value = true; }

  Future<void> toggleAudioRecording() async {
    if (isRecording.value) {
      final path = await _recorder.stop();
      isRecording.value = false;
      if (path != null) { selectedAudio.value = File(path); recordedAudioPath.value = path; isFormDirty.value = true; }
    } else {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) { Get.snackbar('Permission', 'Microphone permission required.', snackPosition: SnackPosition.BOTTOM); return; }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      isRecording.value = true;
    }
  }

  void removeAudio() { selectedAudio.value = null; recordedAudioPath.value = null; recordedAudio.value = null; isFormDirty.value = true; }

  Future<void> _fetchLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best));
      issueLocation.value = {'latitude': pos.latitude, 'longitude': pos.longitude, 'accuracy': pos.accuracy, 'capturedAt': DateTime.now().toIso8601String()};
    } catch (e) { debugPrint('[Location] Failed: $e'); }
  }

  Future<bool> _promptAndFetchLocation() async {
    final completer = Completer<bool>();
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [Icon(Icons.location_off_rounded, color: Colors.orange), SizedBox(width: 10), Text('Location Required')]),
      content: const Text('Your location is needed to submit an issue. Please enable location for CivicConnect.'),
      actions: [
        TextButton(onPressed: () { Get.back(); completer.complete(false); }, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            await openAppSettings();
            final status = await Permission.locationWhenInUse.status;
            if (status.isGranted) { await _fetchLocation(); completer.complete(issueLocation.value != null); }
            else { completer.complete(false); }
          },
          child: const Text('Enable Location'),
        ),
      ],
    ), barrierDismissible: false);
    return completer.future;
  }

  bool _validateFieldsOnly() {
    if (description.value.trim().isEmpty) { Get.snackbar('Required', 'Please enter a description.', snackPosition: SnackPosition.BOTTOM); return false; }
    if (selectedCategoryId.value == null) { Get.snackbar('Required', 'Please select a category.', snackPosition: SnackPosition.BOTTOM); return false; }
    if (selectedImages.isEmpty) { Get.snackbar('Photo Required', 'Please attach at least one photo.', snackPosition: SnackPosition.BOTTOM); return false; }
    return true;
  }

  Future<DuplicateCheckResult?> _checkForDuplicate() async {
    final location = issueLocation.value;
    final categoryId = selectedCategoryId.value;
    if (location == null || categoryId == null) return null;
    final lat = (location['latitude'] as num?)?.toDouble();
    final lng = (location['longitude'] as num?)?.toDouble();
    final accuracy = (location['accuracy'] as num?)?.toDouble() ?? IssueConstants.duplicateMinimumRadiusInMeters;
    if (lat == null || lng == null) return null;
    try {
      final snap = await _firestoreService.getIssuesByCategoryForDuplicateCheck(categoryId);
      final candidates = snap.docs.map((d) => IssueModel.fromFirestore(d))
          .where((i) => i.id != null && i.status != 'resolved' && i.status != 'rejected').toList();
      return DuplicateIssueDetector.findNearestDuplicate(candidates: candidates, currentLat: lat, currentLng: lng, currentAccuracyMeters: accuracy);
    } catch (e) { return null; }
  }

  Future<void> submitIssue() async {
    if (!_validateFieldsOnly()) return;
    if (issueLocation.value == null) {
      isSubmitting.value = true;
      final status = await Permission.locationWhenInUse.status;
      if (status.isGranted) await _fetchLocation();
      isSubmitting.value = false;
      if (issueLocation.value == null) {
        final obtained = await _promptAndFetchLocation();
        if (!obtained) return;
      }
    }
    isSubmitting.value = true;
    uploadProgress.value = 0.05;
    final duplicate = await _checkForDuplicate();
    if (duplicate != null) {
      isSubmitting.value = false;
      uploadProgress.value = 0.0;
      Get.dialog(DuplicateIssueDialog(result: duplicate), barrierDismissible: false);
      return;
    }
    await _doSubmit();
  }

  Future<void> markAsDuplicateAndGoBack({required String existingIssueId, required int currentCount, required List<String> currentReporters}) async {
    final user = _auth.currentUser;
    if (user?.email == null) return;
    isSubmitting.value = true;
    try {
      await _firestoreService.incrementDuplicateCount(issueId: existingIssueId, currentCount: currentCount, currentReporters: currentReporters, reporterEmail: user!.email!);
      Get.snackbar('Noted!', 'Your report has been counted. The issue is already being tracked.', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
      isSubmitting.value = false;
      clearForm();
      _navigateCitizenToDashboard();
    } catch (e) { isSubmitting.value = false; Get.snackbar('Error', 'Could not record your report. Please try again.', snackPosition: SnackPosition.BOTTOM); }
  }

  Future<void> _doSubmit() async {
    isSubmitting.value = true;
    uploadProgress.value = 0.1;
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      uploadProgress.value = 0.3;
      final issueRef = _firestore.collection('issues').doc();
      uploadProgress.value = 0.6;
      final imageFiles = selectedImages.map((x) => File(x.path)).toList();
      if (imageFiles.isEmpty && selectedImage.value != null) imageFiles.add(selectedImage.value!);
      final mediaUrls = await StorageService.uploadIssueMedia(issueId: issueRef.id, images: imageFiles, audio: selectedAudio.value, video: selectedVideo.value);
      uploadProgress.value = 0.85;
      final ts = Timestamp.now();
      await issueRef.set({
        'id': issueRef.id, 'categoryId': selectedCategoryId.value,
        'description': description.value.trim(),
        'imageUrl': mediaUrls['imageUrl'], 'imageUrls': mediaUrls['imageUrls'],
        'videoUrl': mediaUrls['videoUrl'], 'audioUrl': mediaUrls['audioUrl'],
        'location': issueLocation.value, 'reporterEmail': user.email,
        'assignedToDept': selectedCategoryId.value ?? 'unassigned',
        'status': 'reported', 'createdAt': FieldValue.serverTimestamp(),
        'statusUpdatedAt': FieldValue.serverTimestamp(), 'statusUpdatedBy': null,
        'lastReassignedAt': null, 'resolution': null, 'resolvedAt': null,
        'rejectionReason': null, 'rejectedAt': null, 'rejectedBy': null,
        'duplicateReportCount': 1, 'duplicateReporters': [],
        'timeline': [{'status': 'reported', 'message': 'Issue reported by citizen', 'updatedBy': user.email, 'updatedByEmail': user.email, 'timestamp': ts}],
      });
      uploadProgress.value = 1.0;
      submitSuccess.value = true;
      Get.snackbar('Success', 'Issue reported successfully!', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
      isSubmitting.value = false;
      uploadProgress.value = 0.0;
      clearForm();
      _navigateCitizenToDashboard();
    } on FirebaseException catch (e) {
      final msg = e.code == 'permission-denied' ? 'Permission denied. Check storage rules.' : 'Failed to submit: ${e.message ?? e.code}';
      Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
      isSubmitting.value = false; uploadProgress.value = 0.0;
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit: $e', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
      isSubmitting.value = false; uploadProgress.value = 0.0;
    }
  }

  void _navigateCitizenToDashboard() {
    if (Get.isRegistered<HomeCitizenController>()) Get.find<HomeCitizenController>().resetToDashboard();
    Get.offAllNamed(AppRoutes.homeCitizen);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (Get.currentRoute != AppRoutes.homeCitizen) Get.offAll(() => const HomeCitizenPage());
    });
  }

  void clearForm() {
    selectedImage.value = null; selectedImagePath.value = null; selectedImages.clear();
    selectedVideo.value = null; selectedVideoPath.value = null;
    selectedAudio.value = null; recordedAudioPath.value = null; recordedAudio.value = null;
    description.value = ''; descriptionTextController.clear();
    selectedCategoryId.value = null; issueLocation.value = null;
    isFormDirty.value = false; submitSuccess.value = false; isRecording.value = false;
  }

  @override
  void onClose() { if (isRecording.value) _recorder.stop(); _recorder.dispose(); descriptionTextController.dispose(); super.onClose(); }
}
