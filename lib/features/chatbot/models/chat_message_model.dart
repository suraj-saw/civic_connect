import 'dart:convert';

enum MessageRole { system, user, assistant }

enum MessageType { text, image, notification }

class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String? imageUrl;       // For image messages
  final String? actionType;     // For action buttons (e.g., 'report_issue')
  final Map<String, dynamic>? actionData;  // Data for actions

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.type = MessageType.text,
    this.imageUrl,
    this.actionType,
    this.actionData,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to the format expected by the OpenAI API.
  Map<String, dynamic> toApiMap() {
    if (type == MessageType.image && imageUrl != null) {
      // Vision API format
      return {
        'role': role.name,
        'content': [
          {'type': 'text', 'text': content},
          {
            'type': 'image_url',
            'image_url': {'url': imageUrl},
          },
        ],
      };
    }
    return {'role': role.name, 'content': content};
  }

  /// Serialize to JSON for persistence.
  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'imageUrl': imageUrl,
        'actionType': actionType,
        'actionData': actionData != null ? jsonEncode(actionData) : null,
      };

  /// Deserialize from JSON.
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: MessageRole.values.firstWhere((r) => r.name == json['role']),
        content: json['content'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        type: MessageType.values.firstWhere(
          (t) => t.name == (json['type'] ?? 'text'),
          orElse: () => MessageType.text,
        ),
        imageUrl: json['imageUrl'] as String?,
        actionType: json['actionType'] as String?,
        actionData: json['actionData'] != null
            ? jsonDecode(json['actionData'] as String) as Map<String, dynamic>?
            : null,
      );

  factory ChatMessage.user(String content) => ChatMessage(
        role: MessageRole.user,
        content: content,
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        role: MessageRole.assistant,
        content: content,
      );

  factory ChatMessage.system(String content) => ChatMessage(
        role: MessageRole.system,
        content: content,
      );

  factory ChatMessage.image({
    required String caption,
    required String imageUrl,
    required MessageRole role,
  }) =>
      ChatMessage(
        role: role,
        content: caption,
        type: MessageType.image,
        imageUrl: imageUrl,
      );

  factory ChatMessage.withAction({
    required String content,
    required String actionType,
    Map<String, dynamic>? actionData,
  }) =>
      ChatMessage(
        role: MessageRole.assistant,
        content: content,
        actionType: actionType,
        actionData: actionData,
      );

  factory ChatMessage.notification(String content) => ChatMessage(
        role: MessageRole.assistant,
        content: content,
        type: MessageType.notification,
      );
}
