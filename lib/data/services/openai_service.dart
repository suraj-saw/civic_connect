import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4.1-mini';

  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  /// Standard chat completion (non-streaming).
  Future<String> getChatCompletion(List<Map<String, dynamic>> messages) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      throw OpenAIException(
        'OpenAI API key not found. Add OPENAI_API_KEY to your .env file.',
        type: OpenAIErrorType.missingKey,
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      return _parseResponse(response);
    } on OpenAIException {
      rethrow;
    } catch (e) {
      throw OpenAIException(
        'Connection failed. Please check your internet and try again.',
        type: OpenAIErrorType.networkError,
      );
    }
  }

  /// Streaming chat completion — yields text chunks as they arrive.
  Stream<String> streamChatCompletion(List<Map<String, dynamic>> messages) async* {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      throw OpenAIException(
        'OpenAI API key not found. Add OPENAI_API_KEY to your .env file.',
        type: OpenAIErrorType.missingKey,
      );
    }

    try {
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      });
      request.body = jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 1024,
        'temperature': 0.7,
        'stream': true,
      });

      final client = http.Client();
      try {
        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode != 200) {
          final body = await streamedResponse.stream.bytesToString();
          final parsed = jsonDecode(body) as Map<String, dynamic>;
          final errorMsg = parsed['error']?['message'] ?? 'Unknown error';
          throw OpenAIException(
            'API error (${streamedResponse.statusCode}): $errorMsg',
            type: _errorTypeFromStatus(streamedResponse.statusCode),
          );
        }

        String buffer = '';
        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          buffer += chunk;
          // Process complete SSE lines
          while (buffer.contains('\n')) {
            final lineEnd = buffer.indexOf('\n');
            final line = buffer.substring(0, lineEnd).trim();
            buffer = buffer.substring(lineEnd + 1);

            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              if (data == '[DONE]') return;

              try {
                final json = jsonDecode(data) as Map<String, dynamic>;
                final choices = json['choices'] as List<dynamic>?;
                if (choices != null && choices.isNotEmpty) {
                  final delta = choices[0]['delta'] as Map<String, dynamic>?;
                  final content = delta?['content'] as String?;
                  if (content != null) {
                    yield content;
                  }
                }
              } catch (_) {
                // Skip malformed JSON chunks
              }
            }
          }
        }
      } finally {
        client.close();
      }
    } on OpenAIException {
      rethrow;
    } catch (e) {
      throw OpenAIException(
        'Connection failed. Please check your internet and try again.',
        type: OpenAIErrorType.networkError,
      );
    }
  }

  String _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      if (choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>;
        return message['content'] as String? ?? '';
      }
      throw OpenAIException(
        'No response generated. Please try again.',
        type: OpenAIErrorType.emptyResponse,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final errorMsg = body['error']?['message'] ?? 'Unknown error';
      throw OpenAIException(
        'API error (${response.statusCode}): $errorMsg',
        type: _errorTypeFromStatus(response.statusCode),
      );
    }
  }

  OpenAIErrorType _errorTypeFromStatus(int statusCode) {
    switch (statusCode) {
      case 401:
        return OpenAIErrorType.authError;
      case 429:
        return OpenAIErrorType.rateLimited;
      default:
        return OpenAIErrorType.apiError;
    }
  }
}

enum OpenAIErrorType {
  missingKey,
  authError,
  rateLimited,
  apiError,
  emptyResponse,
  networkError,
}

class OpenAIException implements Exception {
  final String message;
  final OpenAIErrorType type;

  OpenAIException(this.message, {required this.type});

  @override
  String toString() => message;
}
