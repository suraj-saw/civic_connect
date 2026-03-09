import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  /* ================= STATE ================= */

  final selectedImages = RxList<XFile>();
  final selectedImagePath = Rxn<String>();
  final Rx<File?> selectedImage = Rx<File?>(null);

  final Rx<File?> selectedVideo = Rx<File?>(null);
  final selectedVideoPath = Rxn<String>();

  final Rx<File?> selectedAudio = Rx<File?>(null);
  final recordedAudioPath = Rxn<String>();
  final recordedAudio = Rxn<File>();

  final isRecording = false.obs;
  final isSubmitting = false.obs;
  final uploadProgress = 0.0.obs;

  final description = ''.obs;
  final selectedCategoryId = Rxn<String>();
  final isFormDirty = false.obs;
  final submitSuccess = false.obs;

  /// Location — fetched only ONCE, never null-checked again after first capture.
  final Rx<Map<String, dynamic>?> issueLocation =
      Rx<Map<String, dynamic>?>(null);

  /* ================= IMAGE (camera only, multi-shot) ================= */

  /// Opens camera — can be called multiple times to add more photos.
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    selectedImage.value = File(image.path);
    selectedImagePath.value = image.path;
    selectedImages.add(image);
    isFormDirty.value = true;

    await _captureLocationOnce();
  }

  Future<void> captureImage() => pickImage();

  void removeImage(int index) {
    selectedImages.removeAt(index);
    if (selectedImages.isEmpty) {
      selectedImage.value = null;
      selectedImagePath.value = null;
    } else {
      selectedImage.value = File(selectedImages.first.path);
      selectedImagePath.value = selectedImages.first.path;
    }
    isFormDirty.value = true;
  }

  void removeAllImages() {
    selectedImage.value = null;
    selectedImagePath.value = null;
    selectedImages.clear();
    isFormDirty.value = true;
  }

  /* ================= VIDEO (camera only) ================= */

  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video == null) return;

    selectedVideo.value = File(video.path);
    selectedVideoPath.value = video.path;
    isFormDirty.value = true;

    await _captureLocationOnce();
  }

  Future<void> captureVideo() => pickVideo();

  void removeVideo() {
    selectedVideo.value = null;
    selectedVideoPath.value = null;
    isFormDirty.value = true;
  }

  /* ================= AUDIO ================= */

  Future<void> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        Get.snackbar('Permission Denied',
            'Microphone permission is required to record audio',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/issue_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      isRecording.value = true;
    } catch (e) {
      Get.snackbar('Recording Error', 'Could not start recording',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _recorder.stop();
      isRecording.value = false;
      if (path != null) {
        final file = File(path);
        recordedAudio.value = file;
        recordedAudioPath.value = path;
        selectedAudio.value = file;
        isFormDirty.value = true;
        Get.snackbar('Voice Recorded', 'Voice description added successfully',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      isRecording.value = false;
    }
  }

  Future<void> toggleAudioRecording() async {
    if (isRecording.value) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  void setAudio(File? audio) {
    selectedAudio.value = audio;
    if (audio != null) {
      recordedAudioPath.value = audio.path;
      isFormDirty.value = true;
    }
  }

  void removeAudio() {
    selectedAudio.value = null;
    recordedAudioPath.value = null;
    recordedAudio.value = null;
    isFormDirty.value = true;
  }

  void clearAudio() => removeAudio();

  /* ================= LOCATION ================= */

  Future<void> captureCurrentLocation() => _captureLocationOnce();

  Future<void> _captureLocationOnce() async {
    if (issueLocation.value != null) return;
    await _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Location Disabled', 'Please enable location services',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      issueLocation.value = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'capturedAt': DateTime.now().toIso8601String(),
      };

      Get.snackbar(
        'Location Captured',
        'Location attached (±${position.accuracy.toStringAsFixed(1)} m)',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      // Location is optional — silent failure keeps form usable.
    }
  }

  /* ================= VALIDATION ================= */

  bool validateForm() {
    if (description.value.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Please enter a description',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (selectedCategoryId.value == null) {
      Get.snackbar('Validation Error', 'Please select a category',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    return true;
  }

  /* ================= DUPLICATE CHECK ================= */

  /// Queries Firestore for recent issues in the same category and checks
  /// whether any of them fall within the GPS-accuracy-derived match radius.
  ///
  /// Returns the nearest [DuplicateCheckResult] or `null` if this is a
  /// genuinely new issue (or when location is unavailable / check fails).
  Future<DuplicateCheckResult?> _checkForDuplicate() async {
    final location = issueLocation.value;
    final categoryId = selectedCategoryId.value;

    // Duplicate check requires both location and category.
    if (location == null || categoryId == null) return null;

    final lat = (location['latitude'] as num?)?.toDouble();
    final lng = (location['longitude'] as num?)?.toDouble();
    final accuracy = (location['accuracy'] as num?)?.toDouble() ??
        IssueConstants.duplicateMinimumRadiusInMeters;

    if (lat == null || lng == null) return null;

    try {
      final snapshot = await _firestoreService
          .getIssuesByCategoryForDuplicateCheck(categoryId);

      // Exclude already-resolved / rejected issues only.
      // We intentionally keep the current user's own previous reports in the
      // candidate list — if they try to report the same issue again from the
      // same location, they should see the duplicate warning.
      final candidates = snapshot.docs
          .map((doc) => IssueModel.fromFirestore(doc))
          .where((issue) =>
              issue.id != null &&
              issue.status != 'resolved' &&
              issue.status != 'rejected')
          .toList();

      return DuplicateIssueDetector.findNearestDuplicate(
        candidates: candidates,
        currentLat: lat,
        currentLng: lng,
        currentAccuracyMeters: accuracy,
      );
    } catch (e) {
      // Duplicate check is best-effort. If anything fails, proceed normally.
      debugPrint('[DuplicateCheck] Error during duplicate check: $e');
      return null;
    }
  }

  /* ================= SUBMIT ================= */

  /// Entry point for the "Submit Issue" button.
  ///
  /// Step 1 — run duplicate check.
  /// Step 2a — if duplicate found: show [DuplicateIssueDialog] and return.
  /// Step 2b — if no duplicate: proceed with [_doSubmit].
  Future<void> submitIssue() async {
    if (!validateForm()) return;

    isSubmitting.value = true;
    uploadProgress.value = 0.05;

    final duplicate = await _checkForDuplicate();

    if (duplicate != null) {
      // Reset state so the form remains editable if the citizen cancels.
      isSubmitting.value = false;
      uploadProgress.value = 0.0;
      Get.dialog(
        DuplicateIssueDialog(result: duplicate),
        barrierDismissible: false,
      );
      return;
    }

    await _doSubmit();
  }

  /// Called from [DuplicateIssueDialog] when the citizen chooses
  /// "I've Seen This Too" — increments the counter on the existing issue
  /// and navigates the citizen back to the dashboard.
  Future<void> markAsDuplicateAndGoBack({
    required String existingIssueId,
    required int currentCount,
    required List<String> currentReporters,
  }) async {
    final user = _auth.currentUser;
    if (user?.email == null) return;

    isSubmitting.value = true;

    try {
      await _firestoreService.incrementDuplicateCount(
        issueId: existingIssueId,
        currentCount: currentCount,
        currentReporters: currentReporters,
        reporterEmail: user!.email!,
      );

      Get.snackbar(
        'Noted!',
        'Your report has been counted. The issue is already being tracked.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      isSubmitting.value = false;
      clearForm();
      _navigateCitizenToDashboard();
    } catch (e) {
      isSubmitting.value = false;
      Get.snackbar(
        'Error',
        'Could not record your report. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Performs the actual Firestore write and Storage uploads.
  /// Separated from [submitIssue] so it can be called directly after the
  /// citizen dismisses the duplicate dialog via "Report Separately".
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
      if (imageFiles.isEmpty && selectedImage.value != null) {
        imageFiles.add(selectedImage.value!);
      }

      final mediaUrls = await StorageService.uploadIssueMedia(
        issueId: issueRef.id,
        images: imageFiles,
        audio: selectedAudio.value,
        video: selectedVideo.value,
      );

      uploadProgress.value = 0.85;

      final timelineTimestamp = Timestamp.now();

      await issueRef.set({
        'id': issueRef.id,
        'categoryId': selectedCategoryId.value,
        'description': description.value.trim(),
        'imageUrl': mediaUrls['imageUrl'],
        'imageUrls': mediaUrls['imageUrls'],
        'videoUrl': mediaUrls['videoUrl'],
        'audioUrl': mediaUrls['audioUrl'],
        'location': issueLocation.value,
        'reporterEmail': user.email,
        'assignedToDept': selectedCategoryId.value ?? 'unassigned',
        'status': 'reported',
        'createdAt': FieldValue.serverTimestamp(),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': null,
        'lastReassignedAt': null,
        'lastReassignedBy': null,
        'resolution': null,
        'resolvedAt': null,
        'rejectionReason': null,
        'rejectedAt': null,
        'rejectedBy': null,
        // Duplicate tracking — starts at 1 (the original reporter counts as 1).
        'duplicateReportCount': 1,
        'duplicateReporters': [],
        'timeline': [
          {
            'status': 'reported',
            'message': 'Issue reported by citizen',
            'updatedBy': user.email,
            'updatedByEmail': user.email,
            'timestamp': timelineTimestamp,
          }
        ],
      });

      uploadProgress.value = 1.0;
      submitSuccess.value = true;

      Get.snackbar(
        'Success',
        'Issue reported successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      isSubmitting.value = false;
      uploadProgress.value = 0.0;
      clearForm();

      _navigateCitizenToDashboard();
    } on FirebaseException catch (e) {
      final message = e.code == 'permission-denied'
          ? 'Upload blocked by Firebase Storage rules. Please update storage.rules.'
          : 'Failed to submit issue: ${e.message ?? e.code}';
      Get.snackbar('Error', message,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3));
      isSubmitting.value = false;
      uploadProgress.value = 0.0;
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit issue: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3));
      isSubmitting.value = false;
      uploadProgress.value = 0.0;
    }
  }

  void _navigateCitizenToDashboard() {
    if (Get.isRegistered<HomeCitizenController>()) {
      Get.find<HomeCitizenController>().resetToDashboard();
    }
    Get.offAllNamed(AppRoutes.homeCitizen);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (Get.currentRoute != AppRoutes.homeCitizen) {
        Get.offAll(() => const HomeCitizenPage());
      }
    });
  }

  /* ================= CLEAR FORM ================= */

  void clearForm() {
    selectedImage.value = null;
    selectedImagePath.value = null;
    selectedImages.clear();
    selectedVideo.value = null;
    selectedVideoPath.value = null;
    selectedAudio.value = null;
    recordedAudioPath.value = null;
    recordedAudio.value = null;
    description.value = '';
    selectedCategoryId.value = null;
    issueLocation.value = null;
    isFormDirty.value = false;
    submitSuccess.value = false;
    isRecording.value = false;
  }

  @override
  void onClose() {
    if (isRecording.value) _recorder.stop();
    _recorder.dispose();
    super.onClose();
  }
}