
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/media_upload_service.dart';

class ReportIssueController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  /* ================= STATE ================= */

  final Rx<File?> selectedImage = Rx<File?>(null);
  final Rx<File?> recordedAudio = Rx<File?>(null);
  final Rx<File?> recordedVideo = Rx<File?>(null);

  final RxBool isRecordingAudio = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxString descriptionText = ''.obs;
  final RxString selectedCategoryId = ''.obs;

  /// 📍 Location
  final Rx<Map<String, dynamic>?> issueLocation = Rx<Map<String, dynamic>?>(null);

  /* ================= IMAGE (Using Native Camera) ================= */

  Future<void> capturePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (image == null) return;

    selectedImage.value = File(image.path);
    await _captureLocation(source: "camera");
  }

  void removeImage() {
    selectedImage.value = null;
    // Don't clear location if video exists
    if (recordedVideo.value == null) {
      issueLocation.value = null;
    }
  }

  /* ================= VIDEO (Using Native Camera) ================= */

  Future<void> captureVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxDuration: const Duration(minutes: 2), // Optional: limit video length
    );

    if (video == null) return;

    recordedVideo.value = File(video.path);
    await _captureLocation(source: "video_camera");

    Get.snackbar(
      "Video Captured",
      "Video recorded successfully",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void removeVideo() {
    recordedVideo.value = null;
    // Don't clear location if image exists
    if (selectedImage.value == null) {
      issueLocation.value = null;
    }
  }

  /* ================= LOCATION ================= */

  Future<void> _captureLocation({required String source}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      issueLocation.value = {
        "latitude": position.latitude,
        "longitude": position.longitude,
        "accuracy": position.accuracy,
        "source": source,
        "capturedAt": FieldValue.serverTimestamp(),
      };

      Get.snackbar(
        "Location Captured",
        "Location attached (±${position.accuracy.toStringAsFixed(1)} m)",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("❌ Location error: $e");
      Get.snackbar(
        "Location Error",
        "Unable to fetch location",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /* ================= VOICE ================= */

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      Get.snackbar("Permission", "Microphone permission required");
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/issue_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    isRecordingAudio.value = true;
  }

  Future<void> stopRecording() async {
    final path = await _recorder.stop();
    isRecordingAudio.value = false;

    if (path != null) {
      recordedAudio.value = File(path);
      Get.snackbar("Voice", "Voice recorded successfully");
    }
  }

  /* ================= VALIDATION ================= */

  bool _validate() {
    // Either image OR video is required
    if (selectedImage.value == null && recordedVideo.value == null) {
      Get.snackbar("Validation Error", "Photo or video is required");
      return false;
    }

    if (descriptionText.value.trim().isEmpty && recordedAudio.value == null) {
      Get.snackbar(
        "Validation Error",
        "Add description via text or voice",
      );
      return false;
    }

    if (selectedCategoryId.value.isEmpty) {
      Get.snackbar("Validation Error", "Select a category");
      return false;
    }

    if (issueLocation.value == null) {
      Get.snackbar("Validation Error", "Location not captured");
      return false;
    }

    return true;
  }

  /* ================= SUBMIT ================= */

  Future<void> submitIssue({
    required String reporterEmail,
  }) async {
    if (!_validate()) return;

    isSubmitting.value = true;

    try {
      print("🔄 Starting upload...");
      print("📷 Image: ${selectedImage.value?.path}");
      print("🎙️ Audio: ${recordedAudio.value?.path}");
      print("🎥 Video: ${recordedVideo.value?.path}");

      final mediaUrls = await MediaUploadService.upload(
        image: selectedImage.value,
        audio: recordedAudio.value,
        video: recordedVideo.value,
      );

      print("✅ Upload successful!");
      print("🖼️ Image URL: ${mediaUrls['imageUrl']}");
      print("🎙️ Audio URL: ${mediaUrls['audioUrl']}");
      print("🎥 Video URL: ${mediaUrls['videoUrl']}");

      final department = selectedCategoryId.value;

      print("🔄 Writing to Firestore...");

      await _firestore.collection('issues').add({
        /* ================= MEDIA ================= */
        "imageUrl": mediaUrls['imageUrl'],
        "audioUrl": mediaUrls['audioUrl'],
        "videoUrl": mediaUrls['videoUrl'],

        /* ================= CONTENT ================= */
        "description": descriptionText.value.trim(),
        "categoryId": selectedCategoryId.value,

        /* ================= ROUTING ================= */
        "departmentId": department,
        "assignedToDept": department,

        /* ================= META ================= */
        "status": "reported",
        "createdAt": FieldValue.serverTimestamp(),
        "reporterEmail": reporterEmail,

        /* ================= LOCATION ================= */
        "location": issueLocation.value,

        /* ================= REASSIGNMENT META ================= */
        "lastReassignedAt": null,
        "lastReassignedBy": null,
      });

      print("✅ Firestore write successful!");

      // Clear all fields after successful submission
      selectedImage.value = null;
      recordedAudio.value = null;
      recordedVideo.value = null;
      descriptionText.value = '';
      selectedCategoryId.value = '';
      issueLocation.value = null;

      Get.back();
      Get.snackbar("Success", "Issue reported successfully");
    } catch (e) {
      print("❌ ERROR: $e");
      print("❌ ERROR TYPE: ${e.runtimeType}");
      Get.snackbar("Error", "Failed to report issue: $e");
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    _recorder.dispose();
    super.onClose();
  }
}