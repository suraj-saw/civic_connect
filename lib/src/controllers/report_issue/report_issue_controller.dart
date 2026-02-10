// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:record/record.dart';
// import 'package:geolocator/geolocator.dart';
//
// import '../../services/media_upload_service.dart';
//
// class ReportIssueController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ImagePicker _picker = ImagePicker();
//   final AudioRecorder _recorder = AudioRecorder();
//
//   /* ================= STATE ================= */
//
//   final Rx<File?> selectedImage = Rx<File?>(null);
//   final Rx<File?> selectedVideo = Rx<File?>(null);
//   final Rx<File?> recordedAudio = Rx<File?>(null);
//
//   final RxBool isRecording = false.obs;
//   final RxBool isSubmitting = false.obs;
//
//   final RxString descriptionText = ''.obs;
//   final RxString selectedCategoryId = ''.obs;
//
//   /// 📍 Location
//   final Rx<Map<String, dynamic>?> issueLocation =
//   Rx<Map<String, dynamic>?>(null);
//
//   /* ================= IMAGE ================= */
//
//   Future<void> pickFromCamera() async {
//     final XFile? image =
//     await _picker.pickImage(source: ImageSource.camera);
//
//     if (image == null) return;
//
//     selectedImage.value = File(image.path);
//     await _captureLocation(source: "camera");
//   }
//
//   Future<void> pickFromGallery() async {
//     final XFile? image =
//     await _picker.pickImage(source: ImageSource.gallery);
//
//     if (image == null) return;
//
//     selectedImage.value = File(image.path);
//     await _captureLocation(source: "gallery");
//   }
//
//   void removeImage() {
//     selectedImage.value = null;
//     issueLocation.value = null;
//   }
//
//   /* ================= VIDEO ================= */
//
//   Future<void> pickVideoFromCamera() async {
//     final XFile? video =
//     await _picker.pickVideo(source: ImageSource.camera);
//
//     if (video == null) return;
//
//     selectedVideo.value = File(video.path);
//     await _captureLocation(source: "video_camera");
//   }
//
//   Future<void> pickVideoFromGallery() async {
//     final XFile? video =
//     await _picker.pickVideo(source: ImageSource.gallery);
//
//     if (video == null) return;
//
//     selectedVideo.value = File(video.path);
//     await _captureLocation(source: "video_gallery");
//   }
//
//   void removeVideo() {
//     selectedVideo.value = null;
//   }
//
//   /* ================= LOCATION ================= */
//
//   Future<void> _captureLocation({required String source}) async {
//     try {
//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.best,
//         ),
//       );
//
//       issueLocation.value = {
//         "latitude": position.latitude,
//         "longitude": position.longitude,
//         "accuracy": position.accuracy,
//         "source": source,
//         "capturedAt": FieldValue.serverTimestamp(),
//       };
//
//       Get.snackbar(
//         "Location Captured",
//         "Location attached (±${position.accuracy.toStringAsFixed(1)} m)",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } catch (e) {
//       Get.snackbar(
//         "Location Error",
//         "Unable to fetch location",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }
//
//   /* ================= VOICE ================= */
//
//   Future<void> startRecording() async {
//     if (!await _recorder.hasPermission()) {
//       Get.snackbar("Permission", "Microphone permission required");
//       return;
//     }
//
//     final dir = await getTemporaryDirectory();
//     final path =
//         '${dir.path}/issue_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
//
//     await _recorder.start(
//       const RecordConfig(encoder: AudioEncoder.aacLc),
//       path: path,
//     );
//
//     isRecording.value = true;
//   }
//
//   Future<void> stopRecording() async {
//     final path = await _recorder.stop();
//     isRecording.value = false;
//
//     if (path != null) {
//       recordedAudio.value = File(path);
//       Get.snackbar("Voice", "Voice recorded successfully");
//     }
//   }
//
//   void removeAudio() {
//     recordedAudio.value = null;
//   }
//
//   /* ================= VALIDATION ================= */
//
//   bool _validate() {
//     if (selectedImage.value == null && selectedVideo.value == null) {
//       Get.snackbar("Validation Error", "Photo or Video is required");
//       return false;
//     }
//
//     if (descriptionText.value.trim().isEmpty &&
//         recordedAudio.value == null) {
//       Get.snackbar(
//         "Validation Error",
//         "Add description via text or voice",
//       );
//       return false;
//     }
//
//     if (selectedCategoryId.value.isEmpty) {
//       Get.snackbar("Validation Error", "Select a category");
//       return false;
//     }
//
//     if (issueLocation.value == null) {
//       Get.snackbar("Validation Error", "Location not captured");
//       return false;
//     }
//
//     return true;
//   }
//
//   /* ================= SUBMIT ================= */
//
//   Future<void> submitIssue({
//     required String reporterEmail,
//   }) async {
//     if (!_validate()) return;
//
//     isSubmitting.value = true;
//
//     try {
//       final mediaUrls = await MediaUploadService.upload(
//         image: selectedImage.value,
//         audio: recordedAudio.value,
//         video: selectedVideo.value,
//       );
//
//       final department = selectedCategoryId.value;
//
//       await _firestore.collection('issues').add({
//         /* ================= MEDIA ================= */
//         "imageUrl": mediaUrls['imageUrl'],
//         "audioUrl": mediaUrls['audioUrl'],
//         "videoUrl": mediaUrls['videoUrl'],
//
//         /* ================= CONTENT ================= */
//         "description": descriptionText.value.trim(),
//         "categoryId": selectedCategoryId.value,
//
//         /* ================= ROUTING ================= */
//         "departmentId": department,
//         "assignedToDept": department,
//
//         /* ================= META ================= */
//         "status": "reported",
//         "createdAt": FieldValue.serverTimestamp(),
//         "reporterEmail": reporterEmail,
//
//         /* ================= LOCATION ================= */
//         "location": issueLocation.value,
//
//         /* ================= STATUS TRACKING ================= */
//         "statusUpdatedAt": FieldValue.serverTimestamp(),
//         "statusUpdatedBy": null,
//
//         /* ================= REASSIGNMENT META ================= */
//         "lastReassignedAt": null,
//         "lastReassignedBy": null,
//
//         /* ================= RESOLUTION (initially null) ================= */
//         "resolution": null,
//         "resolvedAt": null,
//
//         /* ================= REJECTION (initially null) ================= */
//         "rejectionReason": null,
//         "rejectedAt": null,
//         "rejectedBy": null,
//       });
//
//       Get.back();
//       Get.snackbar("Success", "Issue reported successfully");
//     } catch (e) {
//       Get.snackbar("Error", e.toString());
//     } finally {
//       isSubmitting.value = false;
//     }
//   }
// }


// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:record/record.dart';
//
// import '../../model/issue_model.dart';
//
// class ReportIssueController extends GetxController {
//   final _picker = ImagePicker();
//   final _recorder = AudioRecorder();
//
//   var selectedCategory = Rx<String?>(null);
//   var description = ''.obs;
//   var selectedImagePath = Rx<String?>(null);
//   var selectedVideoPath = Rx<String?>(null);
//   var recordedAudioPath = Rx<String?>(null);
//
//   var isRecording = false.obs;
//   var isSubmitting = false.obs;
//
//   var currentLocation = Rx<Position?>(null);
//
//   @override
//   void onInit() {
//     super.onInit();
//     _getCurrentLocation();
//   }
//
//   Future<void> _getCurrentLocation() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         Get.snackbar('Error', 'Location services are disabled');
//         return;
//       }
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           Get.snackbar('Error', 'Location permission denied');
//           return;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         Get.snackbar('Error', 'Location permission permanently denied');
//         return;
//       }
//
//       currentLocation.value = await Geolocator.getCurrentPosition();
//     } catch (e) {
//       print('Error getting location: $e');
//     }
//   }
//
//   Future<void> pickImage() async {
//     final XFile? image = await _picker.pickImage(source: ImageSource.camera);
//     if (image != null) {
//       selectedImagePath.value = image.path;
//     }
//   }
//
//   Future<void> pickVideo() async {
//     final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
//     if (video != null) {
//       selectedVideoPath.value = video.path;
//     }
//   }
//
//   Future<void> startRecording() async {
//     if (await _recorder.hasPermission()) {
//       final path = '/storage/emulated/0/Download/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
//       await _recorder.start(const RecordConfig(), path: path);
//       isRecording.value = true;
//     }
//   }
//
//   Future<void> stopRecording() async {
//     final path = await _recorder.stop();
//     isRecording.value = false;
//     if (path != null) {
//       recordedAudioPath.value = path;
//     }
//   }
//
//   Future<void> submitIssue() async {
//     if (selectedCategory.value == null || description.value.trim().isEmpty) {
//       Get.snackbar('Error', 'Please fill in all required fields');
//       return;
//     }
//
//     isSubmitting.value = true;
//
//     try {
//       String? imageUrl;
//       String? videoUrl;
//       String? audioUrl;
//
//       // Upload media files
//       if (selectedImagePath.value != null) {
//         imageUrl = await _uploadFile(File(selectedImagePath.value!), 'image');
//       }
//       if (selectedVideoPath.value != null) {
//         videoUrl = await _uploadFile(File(selectedVideoPath.value!), 'video');
//       }
//       if (recordedAudioPath.value != null) {
//         audioUrl = await _uploadFile(File(recordedAudioPath.value!), 'audio');
//       }
//
//       final user = FirebaseAuth.instance.currentUser!;
//       final now = DateTime.now();
//
//       // Create initial timeline entry
//       final initialTimeline = TimelineEntry(
//         status: 'reported',
//         message: 'Issue reported by citizen',
//         updatedBy: user.uid,
//         updatedByEmail: user.email ?? '',
//         timestamp: now,
//       );
//
//       final issue = IssueModel(
//         categoryId: selectedCategory.value!,
//         description: description.value.trim(),
//         imageUrl: imageUrl,
//         videoUrl: videoUrl,
//         audioUrl: audioUrl,
//         location: currentLocation.value != null
//             ? {
//           'latitude': currentLocation.value!.latitude,
//           'longitude': currentLocation.value!.longitude,
//         }
//             : null,
//         reporterEmail: user.email ?? '',
//         assignedToDept: selectedCategory.value!,
//         status: 'reported',
//         createdAt: now,
//         timeline: [initialTimeline],
//       );
//
//       await FirebaseFirestore.instance.collection('issues').add(issue.toMap());
//
//       Get.snackbar('Success', 'Issue reported successfully');
//       _resetForm();
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to submit issue: $e');
//     } finally {
//       isSubmitting.value = false;
//     }
//   }
//
//   Future<String> _uploadFile(File file, String type) async {
//     final uri = Uri.parse('http://10.0.2.2:3000/upload');
//     final request = http.MultipartRequest('POST', uri);
//     request.files.add(await http.MultipartFile.fromPath(type, file.path));
//
//     final response = await request.send();
//     final responseData = await response.stream.bytesToString();
//
//     if (response.statusCode == 200) {
//       final jsonResponse = responseData;
//       // Parse and return URL based on type
//       if (type == 'image') {
//         return jsonResponse.split('"imageUrl":"')[1].split('"')[0];
//       } else if (type == 'video') {
//         return jsonResponse.split('"videoUrl":"')[1].split('"')[0];
//       } else {
//         return jsonResponse.split('"audioUrl":"')[1].split('"')[0];
//       }
//     } else {
//       throw Exception('Failed to upload file');
//     }
//   }
//
//   void _resetForm() {
//     selectedCategory.value = null;
//     description.value = '';
//     selectedImagePath.value = null;
//     selectedVideoPath.value = null;
//     recordedAudioPath.value = null;
//   }
// }



import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../model/issue_model.dart';
import '../../services/firebase_storage_service.dart';

class ReportIssueController extends GetxController {
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();

  var selectedCategory = Rx<String?>(null);
  var description = ''.obs;
  var selectedImagePath = Rx<String?>(null);
  var selectedVideoPath = Rx<String?>(null);
  var recordedAudioPath = Rx<String?>(null);

  var isRecording = false.obs;
  var isSubmitting = false.obs;
  var uploadProgress = 0.0.obs; // NEW: Track upload progress

  var currentLocation = Rx<Position?>(null);

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Error', 'Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Error', 'Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('Error', 'Location permission permanently denied');
        return;
      }

      currentLocation.value = await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      selectedImagePath.value = image.path;
    }
  }

  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      selectedVideoPath.value = video.path;
    }
  }

  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      isRecording.value = true;
    }
  }

  Future<void> stopRecording() async {
    final path = await _recorder.stop();
    isRecording.value = false;
    if (path != null) {
      recordedAudioPath.value = path;
    }
  }

  Future<void> submitIssue() async {
    // Validation
    if (selectedCategory.value == null || description.value.trim().isEmpty) {
      Get.snackbar('Error', 'Please fill in all required fields');
      return;
    }

    isSubmitting.value = true;
    uploadProgress.value = 0.0;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();

      // STEP 1: Create issue document first to get issueId
      final issueRef = FirebaseFirestore.instance.collection('issues').doc();
      final issueId = issueRef.id;

      print('📝 Created issue document with ID: $issueId');
      uploadProgress.value = 0.1;

      // STEP 2: Upload media files in parallel (MUCH FASTER)
      print('📤 Starting parallel upload...');
      final mediaUrls = await _uploadMediaParallel(issueId);

      uploadProgress.value = 0.7;
      print('✅ All media uploaded successfully');

      // STEP 3: Create initial timeline entry
      final initialTimeline = TimelineEntry(
        status: 'reported',
        message: 'Issue reported by citizen',
        updatedBy: user.uid,
        updatedByEmail: user.email ?? '',
        timestamp: now,
      );

      uploadProgress.value = 0.8;

      // STEP 4: Create issue object
      final issue = IssueModel(
        categoryId: selectedCategory.value!,
        description: description.value.trim(),
        imageUrl: mediaUrls['imageUrl'],
        videoUrl: mediaUrls['videoUrl'],
        audioUrl: mediaUrls['audioUrl'],
        location: currentLocation.value != null
            ? {
          'latitude': currentLocation.value!.latitude,
          'longitude': currentLocation.value!.longitude,
        }
            : null,
        reporterEmail: user.email ?? '',
        assignedToDept: selectedCategory.value!,
        status: 'reported',
        createdAt: now,
        timeline: [initialTimeline],
      );

      uploadProgress.value = 0.9;

      // STEP 5: Save to Firestore
      print('💾 Saving to Firestore...');
      await issueRef.set(issue.toMap());

      uploadProgress.value = 1.0;
      print('✅ Issue saved to Firestore successfully');

      // STEP 6: Clean up form FIRST
      _resetForm();

      // STEP 7: Reset submission state
      isSubmitting.value = false;
      uploadProgress.value = 0.0;

      // STEP 8: Show success message
      Get.snackbar(
        'Success',
        'Issue reported successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // STEP 9: Force navigation back - try multiple approaches
      print('🔙 Attempting navigation back...');

      // Approach 1: Use Get.back() with result
      if (Get.isDialogOpen == false && Get.isBottomSheetOpen == false) {
        Get.back(closeOverlays: true);
        print('✅ Get.back() executed');
      }

      // Approach 2: If still on page after 500ms, force navigation to home
      await Future.delayed(const Duration(milliseconds: 500));
      if (Get.currentRoute == '/reportIssue') {
        print('⚠️ Still on report page, forcing navigation to home...');
        Get.offAllNamed('/homeCitizen');
      }

    } catch (e) {
      print('❌ Submit error: $e');
      Get.snackbar(
        'Error',
        'Failed to submit issue: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      isSubmitting.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// Upload all media files in parallel for better performance
  Future<Map<String, String?>> _uploadMediaParallel(String issueId) async {
    final futures = <Future<MapEntry<String, String?>>>[];

    // Prepare upload tasks
    if (selectedImagePath.value != null) {
      futures.add(
          FirebaseStorageService.uploadIssueMedia(
            issueId: issueId,
            image: File(selectedImagePath.value!),
          ).then((urls) => MapEntry('imageUrl', urls['imageUrl']))
      );
    }

    if (recordedAudioPath.value != null) {
      futures.add(
          FirebaseStorageService.uploadIssueMedia(
            issueId: issueId,
            audio: File(recordedAudioPath.value!),
          ).then((urls) => MapEntry('audioUrl', urls['audioUrl']))
      );
    }

    if (selectedVideoPath.value != null) {
      futures.add(
          FirebaseStorageService.uploadIssueMedia(
            issueId: issueId,
            video: File(selectedVideoPath.value!),
          ).then((urls) => MapEntry('videoUrl', urls['videoUrl']))
      );
    }

    // Wait for all uploads to complete in parallel
    final results = await Future.wait(futures);

    // Combine results
    final mediaUrls = <String, String?>{
      'imageUrl': null,
      'audioUrl': null,
      'videoUrl': null,
    };

    for (final entry in results) {
      mediaUrls[entry.key] = entry.value;
    }

    return mediaUrls;
  }

  void _resetForm() {
    selectedCategory.value = null;
    description.value = '';
    selectedImagePath.value = null;
    selectedVideoPath.value = null;
    recordedAudioPath.value = null;
  }
}