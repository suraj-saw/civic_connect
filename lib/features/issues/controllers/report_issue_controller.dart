


import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ReportIssueController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  /// Location — fetched only ONCE, never null-checked again after first capture
  final Rx<Map<String, dynamic>?> issueLocation =
  Rx<Map<String, dynamic>?>(null);

  /* ================= IMAGE (camera only, multi-shot) ================= */

  /// Opens camera — can be called multiple times to add more photos
  Future<void> pickImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    selectedImage.value = File(image.path);
    selectedImagePath.value = image.path;
    selectedImages.add(image);
    isFormDirty.value = true;

    // Capture GPS only on the very first media item
    await _captureLocationOnce();
  }

  // Alias used by some widgets
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
    final XFile? video =
    await _picker.pickVideo(source: ImageSource.camera);
    if (video == null) return;

    selectedVideo.value = File(video.path);
    selectedVideoPath.value = video.path;
    isFormDirty.value = true;

    // Capture GPS only if not yet captured
    await _captureLocationOnce();
  }

  // Alias used by some widgets
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
      print('startRecording error: $e');
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
      print('stopRecording error: $e');
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

  /* ================= LOCATION ================= */

  // Public alias for widgets that call captureCurrentLocation directly
  Future<void> captureCurrentLocation() => _captureLocationOnce();

  /// Fetches GPS exactly once — if already captured, does nothing (no snackbar)
  Future<void> _captureLocationOnce() async {
    if (issueLocation.value != null) return; // already have it — skip
    await _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Location Disabled',
            'Please enable location services',
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

      // FIX: Use DateTime ISO string — FieldValue.serverTimestamp()
      // is NOT supported inside maps stored inside arrays
      issueLocation.value = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'capturedAt': DateTime.now().toIso8601String(),
      };

      // Show snackbar only once — this method is guarded so it runs once
      Get.snackbar(
        'Location Captured',
        'Location attached (±${position.accuracy.toStringAsFixed(1)} m)',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Location error: $e');
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

  /* ================= SUBMIT ================= */

  Future<void> submitIssue() async {
    if (!validateForm()) return;

    isSubmitting.value = true;
    uploadProgress.value = 0.1;

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      uploadProgress.value = 0.5;

      final issueRef = _firestore.collection('issues').doc();

      // FIX: Use Timestamp.now() inside the timeline array.
      // FieldValue.serverTimestamp() is only valid at the TOP LEVEL of a document,
      // NOT inside arrays or nested maps inside arrays.
      final timelineTimestamp = Timestamp.now();

      await issueRef.set({
        'id': issueRef.id,
        'categoryId': selectedCategoryId.value,
        'description': description.value.trim(),
        'imageUrl': selectedImagePath.value,
        'videoUrl': selectedVideoPath.value,
        'audioUrl': recordedAudioPath.value,
        // location map uses ISO string for capturedAt — never FieldValue here
        'location': issueLocation.value,
        'reporterEmail': user.email,
        'assignedToDept': selectedCategoryId.value ?? 'unassigned',
        'status': 'reported',
        // Top-level fields CAN use FieldValue.serverTimestamp()
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
        // FIX: timeline array uses Timestamp.now() — NOT FieldValue.serverTimestamp()
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

      // Reset state BEFORE Get.back() — prevents setState-after-dispose
      isSubmitting.value = false;
      uploadProgress.value = 0.0;
      clearForm();

      Get.back(result: true);
    } catch (e) {
      print('❌ Submit error: $e');
      Get.snackbar('Error', 'Failed to submit issue: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3));
      isSubmitting.value = false;
      uploadProgress.value = 0.0;
    }
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
