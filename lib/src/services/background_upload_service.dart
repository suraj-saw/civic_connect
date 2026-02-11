import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'firebase_storage_service.dart';

class BackgroundUploadService {
  static Future<void> uploadAndUpdateIssue({
    required String issueId,
    File? image,
    File? audio,
    File? video,
  }) async {
    try {
      print('📤 Background upload started for issue: $issueId');

      // Upload all media in parallel
      final futures = <Future<MapEntry<String, String?>>>[];

      if (image != null) {
        futures.add(
            FirebaseStorageService.uploadIssueMedia(
              issueId: issueId,
              image: image,
            ).then((urls) => MapEntry('imageUrl', urls['imageUrl']))
        );
      }

      if (audio != null) {
        futures.add(
            FirebaseStorageService.uploadIssueMedia(
              issueId: issueId,
              audio: audio,
            ).then((urls) => MapEntry('audioUrl', urls['audioUrl']))
        );
      }

      if (video != null) {
        futures.add(
            FirebaseStorageService.uploadIssueMedia(
              issueId: issueId,
              video: video,
            ).then((urls) => MapEntry('videoUrl', urls['videoUrl']))
        );
      }

      // Wait for all uploads
      final results = await Future.wait(futures);

      // Prepare update data
      final updateData = <String, dynamic>{
        'uploading': false,
        'uploadedAt': FieldValue.serverTimestamp(),
      };

      for (final entry in results) {
        if (entry.value != null) {
          updateData[entry.key] = entry.value;
        }
      }

      // Update Firestore with URLs
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update(updateData);

      print('✅ Background upload completed for issue: $issueId');

    } catch (e) {
      print('❌ Background upload failed for issue $issueId: $e');

      // Mark as failed so user can retry
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'uploading': false,
        'uploadFailed': true,
        'uploadError': e.toString(),
      });

      Get.snackbar(
        'Upload Error',
        'Failed to upload media for issue. Please check your connection.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}