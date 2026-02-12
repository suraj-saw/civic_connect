//
// import 'dart:io';
//
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:path/path.dart' as path;
//
// class StorageService {
//   static final FirebaseStorage _storage = FirebaseStorage.instance;
//
//   /// Upload issue media files in parallel.
//   /// Returns a map with imageUrl, audioUrl, and videoUrl.
//   static Future<Map<String, String?>> uploadIssueMedia({
//     required String issueId,
//     File? image,
//     File? audio,
//     File? video,
//   }) async {
//     final Future<String?> imageFuture = image == null
//         ? Future.value(null)
//         : _uploadFile(
//       file: image,
//       storagePath: 'issues/$issueId/images/${_generateFileName(image)}',
//     );
//
//     final Future<String?> audioFuture = audio == null
//         ? Future.value(null)
//         : _uploadFile(
//       file: audio,
//       storagePath: 'issues/$issueId/audio/${_generateFileName(audio)}',
//     );
//
//     final Future<String?> videoFuture = video == null
//         ? Future.value(null)
//         : _uploadFile(
//       file: video,
//       storagePath: 'issues/$issueId/videos/${_generateFileName(video)}',
//     );
//
//     final results = await Future.wait<String?>([
//       imageFuture,
//       audioFuture,
//       videoFuture,
//     ]);
//
//     return {
//       'imageUrl': results[0],
//       'audioUrl': results[1],
//       'videoUrl': results[2],
//     };
//   }
//
//   /// Upload resolution image.
//   static Future<String> uploadResolutionImage({
//     required String issueId,
//     required File image,
//   }) async {
//     try {
//       return await _uploadFile(
//         file: image,
//         storagePath: 'resolutions/$issueId/${_generateFileName(image)}',
//       );
//     } catch (e) {
//       throw Exception('Failed to upload resolution image: $e');
//     }
//   }
//
//   /// Core upload function.
//   static Future<String> _uploadFile({
//     required File file,
//     required String storagePath,
//   }) async {
//     try {
//       final Reference storageRef = _storage.ref().child(storagePath);
//
//       final SettableMetadata metadata = SettableMetadata(
//         contentType: _getContentType(file),
//       );
//
//       final TaskSnapshot snapshot = await storageRef.putFile(file, metadata);
//       final String downloadUrl = await snapshot.ref.getDownloadURL();
//
//       return downloadUrl;
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   /// Delete issue media (optional - for cleanup).
//   static Future<void> deleteIssueMedia(String issueId) async {
//     try {
//       final Reference issueRef = _storage.ref().child('issues/$issueId');
//       final ListResult result = await issueRef.listAll();
//
//       for (Reference ref in result.items) {
//         await ref.delete();
//       }
//
//       for (Reference prefix in result.prefixes) {
//         await _deleteFolder(prefix);
//       }
//     } catch (_) {
//       // no-op
//     }
//   }
//
//   /// Recursively delete folder.
//   static Future<void> _deleteFolder(Reference ref) async {
//     try {
//       final list = await ref.listAll();
//       for (var file in list.items) {
//         await file.delete();
//       }
//       for (var folder in list.prefixes) {
//         await _deleteFolder(folder);
//       }
//     } catch (_) {
//       // no-op
//     }
//   }
//
//   /// Get content type based on file extension.
//   static String _getContentType(File file) {
//     final extension = path.extension(file.path).toLowerCase();
//     switch (extension) {
//       case '.jpg':
//       case '.jpeg':
//         return 'image/jpeg';
//       case '.png':
//         return 'image/png';
//       case '.gif':
//         return 'image/gif';
//       case '.mp4':
//         return 'video/mp4';
//       case '.mov':
//         return 'video/quicktime';
//       case '.mp3':
//         return 'audio/mpeg';
//       case '.m4a':
//         return 'audio/mp4';
//       case '.wav':
//         return 'audio/wav';
//       default:
//         return 'application/octet-stream';
//     }
//   }
//
//   /// Generate unique filename.
//   static String _generateFileName(File file) {
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     final original = path.basename(file.path);
//     return '${timestamp}_$original';
//   }
// }


import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload issue media files in parallel.
  /// Returns a map with imageUrls (all uploaded image URLs), imageUrl (primary),
  /// audioUrl, and videoUrl.
  static Future<Map<String, dynamic>> uploadIssueMedia({
    required String issueId,
    List<File> images = const [],
    File? audio,
    File? video,
  }) async {
    final imageUploads = images
        .map(
          (image) => _uploadFile(
        file: image,
        storagePath: 'issues/$issueId/images/${_generateFileName(image)}',
      ),
    )
        .toList();

    final Future<String?> audioFuture = audio == null
        ? Future.value(null)
        : _uploadFile(
      file: audio,
      storagePath: 'issues/$issueId/audio/${_generateFileName(audio)}',
    );

    final Future<String?> videoFuture = video == null
        ? Future.value(null)
        : _uploadFile(
      file: video,
      storagePath: 'issues/$issueId/videos/${_generateFileName(video)}',
    );

    final imageUrls = imageUploads.isEmpty
        ? <String>[]
        : await Future.wait<String>(imageUploads);

    final results = await Future.wait<String?>([
      audioFuture,
      videoFuture,
    ]);

    return {
      'imageUrls': imageUrls,
      // keep legacy single-image field for existing UI/readers
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null,
      'audioUrl': results[0],
      'videoUrl': results[1],
    };
  }

  /// Upload resolution image.
  static Future<String> uploadResolutionImage({
    required String issueId,
    required File image,
  }) async {
    try {
      return await _uploadFile(
        file: image,
        storagePath: 'resolutions/$issueId/${_generateFileName(image)}',
      );
    } catch (e) {
      throw Exception('Failed to upload resolution image: $e');
    }
  }

  /// Core upload function.
  static Future<String> _uploadFile({
    required File file,
    required String storagePath,
  }) async {
    try {
      final Reference storageRef = _storage.ref().child(storagePath);

      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(file),
      );

      final TaskSnapshot snapshot = await storageRef.putFile(file, metadata);
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete issue media (optional - for cleanup).
  static Future<void> deleteIssueMedia(String issueId) async {
    try {
      final Reference issueRef = _storage.ref().child('issues/$issueId');
      final ListResult result = await issueRef.listAll();

      for (Reference ref in result.items) {
        await ref.delete();
      }

      for (Reference prefix in result.prefixes) {
        await _deleteFolder(prefix);
      }
    } catch (_) {
      // no-op
    }
  }

  /// Recursively delete folder.
  static Future<void> _deleteFolder(Reference ref) async {
    try {
      final list = await ref.listAll();
      for (var file in list.items) {
        await file.delete();
      }
      for (var folder in list.prefixes) {
        await _deleteFolder(folder);
      }
    } catch (_) {
      // no-op
    }
  }

  /// Get content type based on file extension.
  static String _getContentType(File file) {
    final extension = path.extension(file.path).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
        return 'audio/mp4';
      case '.wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }

  /// Generate unique filename.
  static String _generateFileName(File file) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final original = path.basename(file.path);
    return '${timestamp}_$original';
  }
}
