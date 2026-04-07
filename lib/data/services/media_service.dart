import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_compress/video_compress.dart';

class MediaService {
  // Reduced from 1600 — still sharp on mobile screens, much smaller file
  static const int _imgMaxDim = 1080;
  // Reduced from 85 — 75 is visually indistinguishable for issue photos
  static const int _imgQuality = 75;

  static Future<File> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final target =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        minWidth: _imgMaxDim,
        minHeight: _imgMaxDim,
        quality: _imgQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint('[MediaService] image compress failed: $e');
      return file;
    }
  }

  // Run multiple image compressions in separate isolates via compute()
  static Future<List<File>> compressImages(List<File> files) async {
    return Future.wait(
      files.map((f) => compute(_compressImageInIsolate, f.path)),
    );
  }

  static Future<File> compressVideo(File file) async {
    try {
      final mp4 = await _ensureMp4(file);
      final info = await VideoCompress.compressVideo(
        mp4.path,
        // Lowered from MediumQuality — LowQuality is fine for civic issue docs
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
        // Lowered from 30 — 24fps is sufficient and significantly faster
        frameRate: 24,
      );
      if (info?.file != null) return info!.file!;
    } catch (e) {
      debugPrint('[MediaService] video compress failed: $e');
    }
    return file;
  }

  static Future<File> _ensureMp4(File file) async {
    if (file.path.endsWith('.mp4')) return file;
    final dir = await getTemporaryDirectory();
    final dest = File(
        '${dir.path}/vid_${DateTime.now().millisecondsSinceEpoch}.mp4');
    return file.copy(dest.path);
  }
}

// Top-level function required by compute() — must not be a class method
Future<File> _compressImageInIsolate(String filePath) async {
  return MediaService.compressImage(File(filePath));
}