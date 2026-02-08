import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MediaUploadService {
  static const String _baseUrl = "http://10.10.48.224:3000";
  static const Duration _timeout = Duration(minutes: 5); // 5 minute timeout for large videos

  static Future<Map<String, String?>> upload({
    File? image,
    File? audio,
    File? video,
  }) async {
    try {
      print("📡 Uploading to: $_baseUrl/upload");

      final uri = Uri.parse("$_baseUrl/upload");
      final request = http.MultipartRequest('POST', uri);

      if (image != null) {
        print("📷 Adding image: ${image.path}");
        print("📷 Image size: ${await image.length()} bytes");
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      if (audio != null) {
        print("🎙️ Adding audio: ${audio.path}");
        print("🎙️ Audio size: ${await audio.length()} bytes");
        request.files.add(
          await http.MultipartFile.fromPath('audio', audio.path),
        );
      }

      if (video != null) {
        print("🎥 Adding video: ${video.path}");
        final videoSize = await video.length();
        print("🎥 Video size: ${(videoSize / 1024 / 1024).toStringAsFixed(2)} MB");
        request.files.add(
          await http.MultipartFile.fromPath('video', video.path),
        );
      }

      print("⏳ Sending request...");

      // Send with timeout
      final streamedResponse = await request.send().timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException('Upload timeout - file may be too large or connection is slow');
        },
      );

      print("📥 Response status: ${streamedResponse.statusCode}");

      final response = await http.Response.fromStream(streamedResponse);
      final body = response.body;

      print("📥 Response body: $body");

      if (response.statusCode != 200) {
        throw Exception("Upload failed: ${response.statusCode} - $body");
      }

      final json = jsonDecode(body);

      return {
        "imageUrl": json['imageUrl'],
        "audioUrl": json['audioUrl'],
        "videoUrl": json['videoUrl'],
      };
    } on SocketException catch (e) {
      print("❌ Network Error: $e");
      throw Exception("Cannot connect to server. Check if:\n1. Server is running\n2. IP address is correct (10.10.10.224)\n3. Phone and server are on same network");
    } on TimeoutException catch (e) {
      print("❌ Timeout Error: $e");
      throw Exception("Upload timeout - file too large or slow connection");
    } catch (e) {
      print("❌ MediaUploadService Error: $e");
      rethrow;
    }
  }
}