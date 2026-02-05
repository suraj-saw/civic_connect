
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/media_upload_service.dart';

class ReportIssueController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  /* ================= STATE ================= */

  final Rx<File?> selectedImage = Rx<File?>(null);
  final Rx<File?> recordedAudio = Rx<File?>(null);

  final RxBool isRecording = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxString descriptionText = ''.obs;
  final RxString selectedCategoryId = ''.obs;

  /// 📍 Location
  final Rx<Map<String, dynamic>?> issueLocation =
  Rx<Map<String, dynamic>?>(null);

  /* ================= IMAGE ================= */

  Future<void> pickFromCamera() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    selectedImage.value = File(image.path);
    await _captureLocation(source: "camera");
  }

  Future<void> pickFromGallery() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    selectedImage.value = File(image.path);
    await _captureLocation(source: "gallery");
  }

  void removeImage() {
    selectedImage.value = null;
    issueLocation.value = null;
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
    final path =
        '${dir.path}/issue_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    isRecording.value = true;
  }

  Future<void> stopRecording() async {
    final path = await _recorder.stop();
    isRecording.value = false;

    if (path != null) {
      recordedAudio.value = File(path);
      Get.snackbar("Voice", "Voice recorded successfully");
    }
  }

  /* ================= VALIDATION ================= */

  bool _validate() {
    if (selectedImage.value == null) {
      Get.snackbar("Validation Error", "Photo is required");
      return false;
    }

    if (descriptionText.value.trim().isEmpty &&
        recordedAudio.value == null) {
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

  // Future<void> submitIssue() async {
  //   if (!_validate()) return;
  //
  //   try {
  //     isSubmitting.value = true;
  //
  //     final media = await MediaUploadService.upload(
  //       image: selectedImage.value,
  //       audio: recordedAudio.value,
  //     );
  //
  //     final user = _auth.currentUser;
  //
  //     await _firestore.collection('issues').add({
  //       "imageUrl": media['imageUrl'],
  //       "audioUrl": media['audioUrl'],
  //       "description": descriptionText.value.trim(),
  //       "categoryId": selectedCategoryId.value,
  //       "status": "reported",
  //       "createdAt": FieldValue.serverTimestamp(),
  //       "reporterEmail": user?.email,
  //       "location": issueLocation.value,
  //     });
  //
  //     Get.back();
  //     Get.snackbar("Success", "Issue reported successfully");
  //   } catch (e) {
  //     Get.snackbar("Error", "Failed to report issue");
  //   } finally {
  //     isSubmitting.value = false;
  //   }
  // }


  // Future<void> submitIssue({
  //   required String reporterEmail,
  // }) async {
  //   if (!_validate()) return;
  //   isSubmitting.value = true;
  //   try {
  //     final mediaUrls = await MediaUploadService.upload(
  //       image: selectedImage.value,
  //       audio: recordedAudio.value,
  //     );
  //
  //     final department = selectedCategoryId.value;
  //
  //     await _firestore.collection('issues').add({
  //       // MEDIA
  //       "imageUrl": mediaUrls['imageUrl'],
  //       "audioUrl": mediaUrls['audioUrl'],
  //
  //       // CONTENT
  //       "description": descriptionText.value.trim(),
  //       "categoryId": selectedCategoryId.value,
  //
  //       // ROUTING
  //       "departmentId": department,
  //       "assignedToDept": department,
  //
  //       // META
  //       "status": "reported",
  //       "createdAt": FieldValue.serverTimestamp(),
  //       "reporterEmail": reporterEmail,
  //
  //       // LOCATION (🔥 RESTORED)
  //       "location": issueLocation.value,
  //     });
  //
  //     Get.back();
  //     Get.snackbar("Success", "Issue reported successfully");
  //   } catch (e) {
  //     Get.snackbar("Error", e.toString());
  //   } finally {
  //     isSubmitting.value = false;
  //   }
  // }


  Future<void> submitIssue({
    required String reporterEmail,
  }) async {
    if (!_validate()) return;

    isSubmitting.value = true;

    try {
      final mediaUrls = await MediaUploadService.upload(
        image: selectedImage.value,
        audio: recordedAudio.value,
      );

      final department = selectedCategoryId.value;

      await _firestore.collection('issues').add({
        /* ================= MEDIA ================= */
        "imageUrl": mediaUrls['imageUrl'],
        "audioUrl": mediaUrls['audioUrl'],

        /* ================= CONTENT ================= */
        "description": descriptionText.value.trim(),
        "categoryId": selectedCategoryId.value,

        /* ================= ROUTING ================= */
        "departmentId": department,        // original department
        "assignedToDept": department,       // current owner

        /* ================= META ================= */
        "status": "reported",
        "createdAt": FieldValue.serverTimestamp(),
        "reporterEmail": reporterEmail,

        /* ================= LOCATION ================= */
        "location": issueLocation.value,

        /* ================= REASSIGNMENT META (NEW) ================= */
        "lastReassignedAt": null,
        "lastReassignedBy": null,
      });

      Get.back();
      Get.snackbar("Success", "Issue reported successfully");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }


}
