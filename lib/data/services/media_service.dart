import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_compress/video_compress.dart';

class MediaService {
  static const int _imgMaxDim = 1600;
  static const int _imgQuality = 85;

  static Future<File> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final target = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, target,
        minWidth: _imgMaxDim, minHeight: _imgMaxDim,
        quality: _imgQuality, format: CompressFormat.jpeg, keepExif: false,
      );
      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint('[MediaService] image compress failed: $e');
      return file;
    }
  }

  static Future<File> compressVideo(File file) async {
    try {
      final mp4 = await _ensureMp4(file);
      final info = await VideoCompress.compressVideo(
        mp4.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
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
    final dest = File('${dir.path}/vid_${DateTime.now().millisecondsSinceEpoch}.mp4');
    return file.copy(dest.path);
  }
}