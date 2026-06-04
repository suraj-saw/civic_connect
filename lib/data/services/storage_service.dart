import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class StorageService {
  static final _storage = FirebaseStorage.instance;

  static Future<Map<String, dynamic>> uploadIssueMedia({
    required String issueId,
    required List<File> images,
    File? audio,
    File? video,
  }) async {
    if (kIsWeb) {
      return {
        'imageUrls': <String>[],
        'imageUrl': null,
        'audioUrl': null,
        'videoUrl': null,
      };
    }

    final base = 'issues/$issueId';
    final results = await Future.wait([
      Future.wait(images.map((img) =>
          _upload(img, '$base/images/${_name(img)}'))),
      audio == null
          ? Future<String?>.value(null)
          : _upload(audio, '$base/audio/${_name(audio)}'),
      video == null
          ? Future<String?>.value(null)
          : _upload(video, '$base/videos/${_name(video)}'),
    ]);

    final imageUrls = (results[0] as List).cast<String>();
    return {
      'imageUrls': imageUrls,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null,
      'audioUrl': results[1] as String?,
      'videoUrl': results[2] as String?,
    };
  }

  static Future<Map<String, dynamic>> uploadResolutionMedia({
    required String issueId,
    required List<File> images,
    File? video,
  }) async {
    if (kIsWeb) {
      return {'photoUrls': <String>[], 'videoUrl': null};
    }

    final base = 'resolutions/$issueId';
    final ts = DateTime.now().millisecondsSinceEpoch;

    final results = await Future.wait([
      Future.wait(images.asMap().entries.map((e) =>
          _upload(e.value, '$base/img_${ts}_${e.key}.jpg'))),
      video == null
          ? Future<String?>.value(null)
          : _upload(video, '$base/video_$ts.mp4'),
    ]);

    return {
      'photoUrls': (results[0] as List).cast<String>(),
      'videoUrl': results[1] as String?,
    };
  }

  static Future<String> _upload(File file, String path) async {
    final ref = _storage.ref().child(path);
    final snap = await ref.putFile(
      file,
      SettableMetadata(
        contentType: _contentType(file),
        cacheControl: 'public,max-age=31536000',
      ),
    );
    return snap.ref.getDownloadURL();
  }

  static String _name(File file) =>
      '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';

  static String _contentType(File file) {
    final ext = p.extension(file.path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.mp4':
      case '.temp':
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
}