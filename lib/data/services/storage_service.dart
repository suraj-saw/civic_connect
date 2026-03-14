import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final _storage = FirebaseStorage.instance;

  static Future<Map<String, dynamic>> uploadIssueMedia({
    required String issueId,
    required List<File> images,
    File? audio,
    File? video,
  }) async {
    final imageUploads = images.map((img) => _uploadFile(file: img, storagePath: 'issues/$issueId/images/${_fileName(img)}')).toList();
    final audioFuture = audio == null ? Future.value(null) : _uploadFile(file: audio, storagePath: 'issues/$issueId/audio/${_fileName(audio)}');
    final videoFuture = video == null ? Future.value(null) : _uploadFile(file: video, storagePath: 'issues/$issueId/videos/${_fileName(video)}');

    final imageUrls = imageUploads.isEmpty ? <String>[] : await Future.wait<String>(imageUploads);
    final results = await Future.wait<String?>([audioFuture, videoFuture]);

    return {
      'imageUrls': imageUrls,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null,
      'audioUrl': results[0],
      'videoUrl': results[1],
    };
  }

  static Future<String> uploadResolutionImage({required String issueId, required File image}) async {
    return _uploadFile(file: image, storagePath: 'resolutions/$issueId/${_fileName(image)}');
  }

  static Future<String> _uploadFile({required File file, required String storagePath}) async {
    final ref = _storage.ref().child(storagePath);
    final meta = SettableMetadata(contentType: _contentType(file));
    final snap = await ref.putFile(file, meta);
    return snap.ref.getDownloadURL();
  }

  static String _fileName(File file) => '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';

  static String _contentType(File file) {
    final ext = path.extension(file.path).toLowerCase();
    switch (ext) {
      case '.jpg': case '.jpeg': return 'image/jpeg';
      case '.png': return 'image/png';
      case '.mp4': return 'video/mp4';
      case '.mov': return 'video/quicktime';
      case '.mp3': return 'audio/mpeg';
      case '.m4a': return 'audio/mp4';
      case '.wav': return 'audio/wav';
      default: return 'application/octet-stream';
    }
  }
}
