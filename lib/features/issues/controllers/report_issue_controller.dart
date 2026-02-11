// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
// import 'package:record/record.dart';
//
// import '../../../data/services/storage_service.dart';
// import '../models/issue_category_model.dart';
// import 'issue_category_controller.dart';
// import 'issue_permission_controller.dart';
//
// class ReportIssueController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final ImagePicker _picker = ImagePicker();
//   final AudioRecorder _audioRecorder = AudioRecorder();
//
//   final Rx<File?> selectedImage = Rx<File?>(null);
//   final Rx<File?> selectedVideo = Rx<File?>(null);
//   final Rx<File?> selectedAudio = Rx<File?>(null);
//
//   final RxBool isRecording = false.obs;
//   final RxBool isSubmitting = false.obs;
//
//   final description = ''.obs;
//   final selectedCategoryId = Rxn<String>();
//   final isFormDirty = false.obs;
//
//   final Rx<Map<String, dynamic>?> issueLocation = Rx<Map<String, dynamic>?>(null);
//
//   IssuePermissionController get _permissionController =>
//       Get.find<IssuePermissionController>();
//
//   @override
//   void onInit() {
//     super.onInit();
//     captureCurrentLocation();
//   }
//
//   Future<void> captureCurrentLocation() async {
//     if (!_permissionController.hasLocationPermission) {
//       return;
//     }
//
//     try {
//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.best,
//         ),
//       );
//
//       issueLocation.value = {
//         'latitude': position.latitude,
//         'longitude': position.longitude,
//         'accuracy': position.accuracy,
//       };
//     } catch (_) {
//       // Keep silent and let user continue. Location is optional in case of device failure.
//     }
//   }
//
//   Future<void> captureImage() async {
//     final cameraAllowed = await _permissionController.requestCamera();
//     if (!cameraAllowed) return;
//
//     final XFile? image = await _picker.pickImage(
//       source: ImageSource.camera,
//       maxWidth: 1920,
//       maxHeight: 1920,
//       imageQuality: 85,
//     );
//
//     if (image == null) return;
//
//     selectedImage.value = File(image.path);
//     isFormDirty.value = true;
//     await captureCurrentLocation();
//   }
//
//   void removeImage() {
//     selectedImage.value = null;
//     isFormDirty.value = true;
//   }
//
//   Future<void> captureVideo() async {
//     final cameraAllowed = await _permissionController.requestCamera();
//     if (!cameraAllowed) return;
//
//     final XFile? video = await _picker.pickVideo(
//       source: ImageSource.camera,
//       maxDuration: const Duration(seconds: 60),
//     );
//
//     if (video == null) return;
//
//     selectedVideo.value = File(video.path);
//     isFormDirty.value = true;
//     await captureCurrentLocation();
//   }
//
//   void removeVideo() {
//     selectedVideo.value = null;
//     isFormDirty.value = true;
//   }
//
//   Future<void> toggleAudioRecording() async {
//     if (isRecording.value) {
//       await stopAudioRecording();
//       return;
//     }
//
//     final micAllowed = await _permissionController.requestMic();
//     if (!micAllowed) return;
//
//     try {
//       final appDir = await getApplicationDocumentsDirectory();
//       final filePath = path.join(
//         appDir.path,
//         'issue_audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
//       );
//
//       await _audioRecorder.start(
//         const RecordConfig(
//           encoder: AudioEncoder.aacLc,
//           bitRate: 128000,
//           sampleRate: 44100,
//         ),
//         path: filePath,
//       );
//
//       isRecording.value = true;
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to start audio recording: $e');
//     }
//   }
//
//   Future<void> stopAudioRecording() async {
//     try {
//       final outputPath = await _audioRecorder.stop();
//       isRecording.value = false;
//
//       if (outputPath == null) return;
//
//       final audioFile = File(outputPath);
//       if (!audioFile.existsSync()) return;
//
//       selectedAudio.value = audioFile;
//       isFormDirty.value = true;
//     } catch (e) {
//       isRecording.value = false;
//       Get.snackbar('Error', 'Failed to stop audio recording: $e');
//     }
//   }
//
//   void removeAudio() {
//     selectedAudio.value = null;
//     isFormDirty.value = true;
//   }
//
//   bool validateForm() {
//     return selectedImage.value != null &&
//         description.value.trim().isNotEmpty &&
//         selectedCategoryId.value != null;
//   }
//
//   Future<void> submitIssue() async {
//     if (!validateForm()) {
//       Get.snackbar(
//         'Missing Required Fields',
//         'Please capture an image, select a category, and add a description.',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }
//
//     isSubmitting.value = true;
//
//     try {
//       final user = _auth.currentUser;
//       if (user == null) throw Exception('User not logged in');
//
//       final issueRef = _firestore.collection('issues').doc();
//       final category = _getSelectedCategory();
//
//       final uploadedMedia = await StorageService.uploadIssueMedia(
//         issueId: issueRef.id,
//         image: selectedImage.value,
//         audio: selectedAudio.value,
//         video: selectedVideo.value,
//       );
//
//       final locationData = issueLocation.value == null
//           ? null
//           : {
//         ...issueLocation.value!,
//         'capturedAt': FieldValue.serverTimestamp(),
//       };
//
//       await issueRef.set({
//         'id': issueRef.id,
//         'categoryId': selectedCategoryId.value,
//         'categoryName': category?.name,
//         'description': description.value.trim(),
//         'imageUrl': uploadedMedia['imageUrl'],
//         'videoUrl': uploadedMedia['videoUrl'],
//         'audioUrl': uploadedMedia['audioUrl'],
//         'location': locationData,
//         'reporterEmail': user.email,
//         'reporterUid': user.uid,
//         'assignedToDept': (category?.assignedDepartment.isNotEmpty ?? false)
//             ? category!.assignedDepartment
//             : (category?.id ?? 'unassigned'),
//         'status': 'reported',
//         'createdAt': FieldValue.serverTimestamp(),
//         'timeline': [
//           {
//             'status': 'reported',
//             'message': 'Issue reported by citizen',
//             'updatedBy': user.email,
//             'updatedByEmail': user.email,
//             'timestamp': Timestamp.now(),
//           }
//         ],
//       });
//
//       Get.snackbar(
//         'Success',
//         'Issue reported successfully.',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//
//       clearForm();
//       Get.back(result: true);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to submit issue: $e');
//     } finally {
//       isSubmitting.value = false;
//     }
//   }
//
//   IssueCategory? _getSelectedCategory() {
//     if (!Get.isRegistered<IssueCategoryController>()) {
//       return null;
//     }
//
//     final categoryController = Get.find<IssueCategoryController>();
//     final id = selectedCategoryId.value;
//     if (id == null) return null;
//
//     try {
//       return categoryController.categories.firstWhere((cat) => cat.id == id);
//     } catch (_) {
//       return null;
//     }
//   }
//
//   void clearForm() {
//     selectedImage.value = null;
//     selectedVideo.value = null;
//     selectedAudio.value = null;
//     description.value = '';
//     selectedCategoryId.value = null;
//     issueLocation.value = null;
//     isFormDirty.value = false;
//   }
//
//   @override
//   void onClose() {
//     _audioRecorder.dispose();
//     super.onClose();
//   }
// }


import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/services/storage_service.dart';
import '../models/issue_category_model.dart';
import 'issue_category_controller.dart';
import 'issue_permission_controller.dart';

class ReportIssueController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  final Rx<File?> selectedImage = Rx<File?>(null);
  final Rx<File?> selectedVideo = Rx<File?>(null);
  final Rx<File?> selectedAudio = Rx<File?>(null);

  final RxBool isRecording = false.obs;
  final RxBool isSubmitting = false.obs;

  final description = ''.obs;
  final selectedCategoryId = Rxn<String>();
  final isFormDirty = false.obs;

  final Rx<Map<String, dynamic>?> issueLocation = Rx<Map<String, dynamic>?>(null);

  IssuePermissionController get _permissionController =>
      Get.find<IssuePermissionController>();

  @override
  void onInit() {
    super.onInit();
    captureCurrentLocation();
  }

  Future<void> captureCurrentLocation() async {
    if (!_permissionController.hasLocationPermission) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      issueLocation.value = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };
    } catch (_) {
      // Keep silent and let user continue. Location is optional in case of device failure.
    }
  }

  Future<void> captureImage() async {
    final cameraAllowed = await _permissionController.requestCamera();
    if (!cameraAllowed) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );

    if (image == null) return;

    selectedImage.value = File(image.path);
    isFormDirty.value = true;
    await captureCurrentLocation();
  }

  void removeImage() {
    selectedImage.value = null;
    isFormDirty.value = true;
  }

  Future<void> captureVideo() async {
    final cameraAllowed = await _permissionController.requestCamera();
    if (!cameraAllowed) return;

    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 45),
    );

    if (video == null) return;

    selectedVideo.value = File(video.path);
    isFormDirty.value = true;
    await captureCurrentLocation();
  }

  void removeVideo() {
    selectedVideo.value = null;
    isFormDirty.value = true;
  }

  Future<void> toggleAudioRecording() async {
    if (isRecording.value) {
      await stopAudioRecording();
      return;
    }

    final micAllowed = await _permissionController.requestMic();
    if (!micAllowed) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = path.join(
        appDir.path,
        'issue_audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      isRecording.value = true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to start audio recording: $e');
    }
  }

  Future<void> stopAudioRecording() async {
    try {
      final outputPath = await _audioRecorder.stop();
      isRecording.value = false;

      if (outputPath == null) return;

      final audioFile = File(outputPath);
      if (!audioFile.existsSync()) return;

      selectedAudio.value = audioFile;
      isFormDirty.value = true;
    } catch (e) {
      isRecording.value = false;
      Get.snackbar('Error', 'Failed to stop audio recording: $e');
    }
  }

  void removeAudio() {
    selectedAudio.value = null;
    isFormDirty.value = true;
  }

  bool validateForm() {
    return selectedImage.value != null &&
        description.value.trim().isNotEmpty &&
        selectedCategoryId.value != null;
  }

  Future<void> submitIssue() async {
    if (!validateForm()) {
      Get.snackbar(
        'Missing Required Fields',
        'Please capture an image, select a category, and add a description.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final issueRef = _firestore.collection('issues').doc();
      final category = _getSelectedCategory();

      final uploadedMedia = await StorageService.uploadIssueMedia(
        issueId: issueRef.id,
        image: selectedImage.value,
        audio: selectedAudio.value,
        video: selectedVideo.value,
      );

      final locationData = issueLocation.value == null
          ? null
          : {
        ...issueLocation.value!,
        'capturedAt': FieldValue.serverTimestamp(),
      };

      await issueRef.set({
        'id': issueRef.id,
        'categoryId': selectedCategoryId.value,
        'categoryName': category?.name,
        'description': description.value.trim(),
        'imageUrl': uploadedMedia['imageUrl'],
        'videoUrl': uploadedMedia['videoUrl'],
        'audioUrl': uploadedMedia['audioUrl'],
        'location': locationData,
        'reporterEmail': user.email,
        'reporterUid': user.uid,
        'assignedToDept': (category?.assignedDepartment.isNotEmpty ?? false)
            ? category!.assignedDepartment
            : (category?.id ?? 'unassigned'),
        'status': 'reported',
        'createdAt': FieldValue.serverTimestamp(),
        'timeline': [
          {
            'status': 'reported',
            'message': 'Issue reported by citizen',
            'updatedBy': user.email,
            'updatedByEmail': user.email,
            'timestamp': Timestamp.now(),
          }
        ],
      });

      Get.snackbar(
        'Success',
        'Issue reported successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();

      if (Get.key.currentState?.canPop() ?? false) {
        Get.back(result: true);
      } else {
        Get.offAllNamed(AppRoutes.homeCitizen);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit issue: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  IssueCategory? _getSelectedCategory() {
    if (!Get.isRegistered<IssueCategoryController>()) {
      return null;
    }

    final categoryController = Get.find<IssueCategoryController>();
    final id = selectedCategoryId.value;
    if (id == null) return null;

    try {
      return categoryController.categories.firstWhere((cat) => cat.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearForm() {
    selectedImage.value = null;
    selectedVideo.value = null;
    selectedAudio.value = null;
    description.value = '';
    selectedCategoryId.value = null;
    issueLocation.value = null;
    isFormDirty.value = false;
  }

  @override
  void onClose() {
    _audioRecorder.dispose();
    super.onClose();
  }
}
