
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MediaUploadService {
  static const String _baseUrl = "https://civicconnect-media-server.onrender.com";
  // use your local IP if testing on real device
  // OR use your deployed server URL

  static Future<Map<String, String?>> upload({
    File? image,
    File? audio,
    File? video,
  }) async {
    final uri = Uri.parse("$_baseUrl/upload");
    final request = http.MultipartRequest('POST', uri);

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    }

    if (audio != null) {
      request.files.add(
        await http.MultipartFile.fromPath('audio', audio.path),
      );
    }

    if (video != null) {
      request.files.add(
        await http.MultipartFile.fromPath('video', video.path),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception("Upload failed");
    }

    final json = jsonDecode(body);

    return {
      "imageUrl": json['imageUrl'],
      "audioUrl": json['audioUrl'],
      "videoUrl": json['videoUrl'],
    };
  }
}