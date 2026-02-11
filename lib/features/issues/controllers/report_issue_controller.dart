import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class ReportIssueController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  /* ================= STATE ================= */

  // Images
  final selectedImages = RxList<XFile>();
  final selectedImagePath = Rxn<String>();
  final Rx<File?> selectedImage = Rx<File?>(null);

  // Video
  final Rx<File?> selectedVideo = Rx<File?>(null);
  final selectedVideoPath = Rxn<String>();

  // Audio
  final Rx<File?> selectedAudio = Rx<File?>(null);
  final recordedAudioPath = Rxn<String>();
  final recordedAudio = Rxn<File>();

  final RxBool isRecording = false.obs;
  final RxBool isSubmitting = false.obs;

  final description = ''.obs;
  final selectedCategoryId = Rxn<String>();
  final isFormDirty = false.obs;
  final submitSuccess = false.obs;

  /// 📍 Location
  final Rx<Map<String, dynamic>?> issueLocation =
  Rx<Map<String, dynamic>?>(null);

  /* ================= IMAGE ================= */

  Future<void> pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      selectedImages.addAll(images);
      isFormDirty.value = true;

      // Also set first image as preview
      if (selectedImage.value == null) {
        selectedImage.value = File(images.first.path);
        selectedImagePath.value = images.first.path;
        await _captureLocation(source: "camera");
      }
    }
  }

  Future<void> pickImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    selectedImage.value = File(image.path);
    selectedImagePath.value = image.path;
    selectedImages.add(image);
    isFormDirty.value = true;
    await _captureLocation(source: "camera");
  }

  Future<void> pickImageFromGallery() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    selectedImage.value = File(image.path);
    selectedImagePath.value = image.path;
    selectedImages.add(image);
    isFormDirty.value = true;
    await _captureLocation(source: "gallery");
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
    isFormDirty.value = true;
  }

  void removeAllImages() {
    selectedImage.value = null;
    selectedImagePath.value = null;
    selectedImages.clear();
    issueLocation.value = null;
  }

  /* ================= VIDEO ================= */

  Future<void> pickVideo() async {
    final XFile? video =
    await _picker.pickVideo(source: ImageSource.camera);

    if (video == null) return;

    selectedVideo.value = File(video.path);
    selectedVideoPath.value = video.path;
    isFormDirty.value = true;
    await _captureLocation(source: "video_camera");
  }

  Future<void> pickVideoFromGallery() async {
    final XFile? video =
    await _picker.pickVideo(source: ImageSource.gallery);

    if (video == null) return;

    selectedVideo.value = File(video.path);
    selectedVideoPath.value = video.path;
    isFormDirty.value = true;
    await _captureLocation(source: "video_gallery");
  }

  void removeVideo() {
    selectedVideo.value = null;
    selectedVideoPath.value = null;
    isFormDirty.value = true;
  }

  /* ================= AUDIO ================= */

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
      print("Location error: $e");
    }
  }

  /* ================= VALIDATION ================= */

  bool validateForm() {
    return description.value.trim().isNotEmpty &&
        selectedCategoryId.value != null;
  }

  /* ================= SUBMIT ================= */

  Future<void> submitIssue() async {
    if (!validateForm()) {
      Get.snackbar("Error", "Please fill all required fields");
      return;
    }

    isSubmitting.value = true;

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final issueRef = _firestore.collection('issues').doc();

      await issueRef.set({
        'id': issueRef.id,
        'categoryId': selectedCategoryId.value,
        'description': description.value,
        'imageUrl': selectedImagePath.value,
        'videoUrl': selectedVideoPath.value,
        'audioUrl': recordedAudioPath.value,
        'location': issueLocation.value,
        'reporterEmail': user.email,
        'assignedToDept': 'unassigned',
        'status': 'reported',
        'createdAt': FieldValue.serverTimestamp(),
        'timeline': [
          {
            'status': 'reported',
            'message': 'Issue reported by citizen',
            'updatedBy': user.email,
            'updatedByEmail': user.email,
            'timestamp': FieldValue.serverTimestamp(),
          }
        ],
      });

      submitSuccess.value = true;

      Get.snackbar(
        "Success",
        "Issue reported successfully",
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
      Get.back(result: true);
    } catch (e) {
      Get.snackbar("Error", "Failed to submit issue: $e");
    } finally {
      isSubmitting.value = false;
    }
  }

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
  }
}