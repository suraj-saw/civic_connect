import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/routes/app_routes.dart';
import '../../../data/services/openai_service.dart';
import '../models/chat_message_model.dart';

class ChatbotController extends GetxController {
  final OpenAIService _openAIService = OpenAIService();
  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final _storage = GetStorage();
  final _picker = ImagePicker();

  // State
  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isStreaming = false.obs;
  final hasError = false.obs;
  final showSuggestions = true.obs;
  final language = 'English'.obs;
  final isListening = false.obs;
  final hasText = false.obs;
  final streamingText = ''.obs;

  // Voice
  final stt.SpeechToText _speech = stt.SpeechToText();
  final speechAvailable = false.obs;

  // User context
  String _userIssuesContext = '';

  static const List<String> quickSuggestions = [
    '🚧 How to report an issue?',
    '📍 Track my complaint',
    '📸 Tips for good photos',
    '❓ What issues can I report?',
    '🗣️ Switch to Hindi',
  ];

  static const String _storageKey = 'civicbot_chat_history';
  static const String _langKey = 'civicbot_language';

  String get _systemPrompt => '''
You are CivicBot, the friendly and knowledgeable AI assistant for CivicConnect — a smart civic issue reporting and resolution platform that bridges the gap between citizens and municipalities.

IMPORTANT: Respond in ${language.value}. ${language.value == 'Hindi' ? 'Use Hinglish (Hindi written in Roman script mixed with English) for technical terms.' : ''}

Your role is to help citizens:
• Report civic issues effectively (potholes, broken streetlights, garbage, water leaks, drainage, road damage, illegal parking, noise pollution, etc.)
• Understand how to use the app (reporting flow, tracking issues, map view, notifications, dashboard)
• Get tips on writing effective issue descriptions and capturing useful photos
• Learn about typical municipal resolution timelines and processes
• Understand issue statuses: Reported → Assigned → In Progress → Resolved
• Know about the duplicate detection system that merges similar reports

App features you know about:
- Dashboard tab: Overview with quick actions — "Report Issue" and "My Reported Issues"
- Map tab: Shows all issues on a map with category filters and multiple styles (Street, Satellite, Outdoors)
- Chat tab: This conversation with you (CivicBot)
- Profile tab: User settings, account management
- Report Issue: Add title, description, category, photos, videos, audio, and GPS location
- Notifications: Real-time updates on status changes

${_userIssuesContext.isNotEmpty ? 'USER\'S REPORTED ISSUES:\n$_userIssuesContext\nUse this data when the user asks about their issues, status, or complaints.' : ''}

Guidelines:
- Keep responses concise and helpful (2-4 sentences when possible)
- Use markdown formatting: **bold** for emphasis, bullet points for lists, numbered steps for instructions
- Use emojis sparingly for friendliness
- If the user wants to report an issue, guide them step-by-step and suggest they tap "Report Issue" from the Dashboard
- Stay focused on civic services — politely redirect unrelated questions
- Be encouraging — thank citizens for improving their community
- Format responses for mobile readability
''';

  @override
  void onInit() {
    super.onInit();
    _initSpeech();
    _loadLanguage();
    _loadChatHistory();
    _loadUserContext();
    textController.addListener(() {
      hasText.value = textController.text.trim().isNotEmpty;
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    textController.dispose();
    focusNode.dispose();
    _speech.cancel();
    super.onClose();
  }



  Future<void> _initSpeech() async {
    speechAvailable.value = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening.value = false;
        }
      },
      onError: (_) => isListening.value = false,
    );
  }

  void _loadLanguage() {
    final saved = _storage.read<String>(_langKey);
    if (saved != null) language.value = saved;
  }

  void _loadChatHistory() {
    final saved = _storage.read<String>(_storageKey);
    if (saved != null) {
      try {
        final list = (jsonDecode(saved) as List)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          messages.addAll(list);
          showSuggestions.value = false;
          _scrollToBottom();
          return;
        }
      } catch (_) {}
    }
    _addWelcomeMessages();
  }

  Future<void> _loadUserContext() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;

      // Simple query — no orderBy to avoid needing composite index
      final snapshot = await FirebaseFirestore.instance
          .collection('issues')
          .where('reporterEmail', isEqualTo: user.email)
          .limit(15)
          .get();

      if (snapshot.docs.isEmpty) {
        _userIssuesContext = 'The user has not reported any issues yet.';
        return;
      }

      // Sort client-side
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aTime = a.data()['createdAt'];
        final bTime = b.data()['createdAt'];
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });

      final buffer = StringBuffer();
      buffer.writeln('Total issues reported by user: ${docs.length}');
      for (final doc in docs) {
        final d = doc.data();
        final status = d['status'] ?? 'reported';
        final category = d['categoryId'] ?? 'unknown';
        final desc = d['description']?.toString() ?? '';
        final title = d['title']?.toString() ??
            (desc.length > 60 ? desc.substring(0, 60) : desc);
        final created = d['createdAt'];
        String timeAgo = '';
        if (created is Timestamp) {
          final diff = DateTime.now().difference(created.toDate());
          if (diff.inDays >= 1) {
            timeAgo = '${diff.inDays}d ago';
          } else if (diff.inHours >= 1) {
            timeAgo = '${diff.inHours}h ago';
          } else {
            timeAgo = 'just now';
          }
        }
        buffer.writeln('- "$title" | Category: $category | Status: $status | Reported: $timeAgo');
      }
      _userIssuesContext = buffer.toString();

      // Update the system prompt with fresh context
      _updateSystemPrompt();
    } catch (e) {
      debugPrint('CivicBot: Failed to load user context: $e');
      _userIssuesContext = '';
    }
  }

  void _addWelcomeMessages() {
    messages.add(ChatMessage.system(_systemPrompt));
    messages.add(ChatMessage.assistant(
      language.value == 'Hindi'
          ? 'Namaste! 👋 CivicConnect mein aapka swagat hai.\n\n'
              'Main **CivicBot** hoon — aapka AI civic assistant. Main aapki madad kar sakta hoon:\n'
              '• Issue report karna\n'
              '• App navigate karna\n'
              '• Complaint track karna\n\n'
              'Aap kya jaanna chahte hain?'
          : 'Hey there! 👋 Welcome to CivicConnect.\n\n'
              'I\'m **CivicBot** — your AI civic assistant. I can help you:\n'
              '• Report civic issues\n'
              '• Navigate the app\n'
              '• Track your complaints\n'
              '• Get reporting tips\n\n'
              'What would you like to know?',
    ));
  }


  void _saveChatHistory() {
    final jsonList = messages.map((m) => m.toJson()).toList();
    _storage.write(_storageKey, jsonEncode(jsonList));
  }

 

  Future<void> sendMessage([String? overrideText]) async {
    final text = (overrideText ?? textController.text).trim();
    if (text.isEmpty || isLoading.value) return;

    // Check for language switch request
    if (_handleLanguageSwitch(text)) return;

    textController.clear();
    hasError.value = false;
    showSuggestions.value = false;

    // Haptic on send
    HapticFeedback.lightImpact();

    messages.add(ChatMessage.user(text));
    _saveChatHistory();
    _scrollToBottom();

    // Refresh user's issues context before each call
    await _loadUserContext();
    _updateSystemPrompt();

    isLoading.value = true;
    isStreaming.value = true;
    streamingText.value = '';

    try {
      final apiMessages = messages.map((m) => m.toApiMap()).toList();

      // Add a placeholder assistant message for streaming
      final streamingMessage = ChatMessage.assistant('');
      messages.add(streamingMessage);

      final buffer = StringBuffer();
      await for (final chunk in _openAIService.streamChatCompletion(apiMessages)) {
        buffer.write(chunk);
        // Update the last message in-place
        messages[messages.length - 1] = ChatMessage.assistant(buffer.toString());
        streamingText.value = buffer.toString();
        _scrollToBottom();
      }

      // Haptic on receive
      HapticFeedback.selectionClick();
    } on OpenAIException catch (e) {
      hasError.value = true;
      if (messages.last.content.isEmpty) {
        messages[messages.length - 1] = ChatMessage.assistant('⚠️ ${e.message}');
      } else {
        messages.add(ChatMessage.assistant('⚠️ ${e.message}'));
      }
    } catch (e) {
      hasError.value = true;
      if (messages.isNotEmpty && messages.last.role == MessageRole.assistant && messages.last.content.isEmpty) {
        messages[messages.length - 1] = ChatMessage.assistant('⚠️ Something went wrong. Please try again.');
      } else {
        messages.add(ChatMessage.assistant('⚠️ Something went wrong. Please try again.'));
      }
    } finally {
      isLoading.value = false;
      isStreaming.value = false;
      streamingText.value = '';
      _saveChatHistory();
      _scrollToBottom();
    }
  }


  Future<void> sendImage({required ImageSource source}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      HapticFeedback.lightImpact();
      showSuggestions.value = false;

      // Convert to base64 for the API
      final bytes = await File(picked.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';

      // Add image message
      messages.add(ChatMessage.image(
        caption: '📷 Sent a photo for analysis',
        imageUrl: picked.path,
        role: MessageRole.user,
      ));
      _saveChatHistory();
      _scrollToBottom();

      _updateSystemPrompt();
      isLoading.value = true;
      isStreaming.value = true;
      streamingText.value = '';

      // Build messages with image for vision API
      final apiMessages = <Map<String, dynamic>>[];
      for (final m in messages) {
        if (m.type == MessageType.image && m.role == MessageRole.user && m == messages[messages.length - 1]) {
          continue; // Skip — we'll add it specially
        }
        apiMessages.add(m.toApiMap());
      }
      // Add the image message in vision format
      apiMessages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': 'Please analyze this image. If it shows a civic issue (pothole, garbage, broken infrastructure, etc.), describe what you see and suggest reporting it. If not, describe the image briefly.'},
          {
            'type': 'image_url',
            'image_url': {'url': dataUrl},
          },
        ],
      });

      // Stream the response
      final streamMsg = ChatMessage.assistant('');
      messages.add(streamMsg);

      final buffer = StringBuffer();
      await for (final chunk in _openAIService.streamChatCompletion(apiMessages)) {
        buffer.write(chunk);
        messages[messages.length - 1] = ChatMessage.assistant(buffer.toString());
        streamingText.value = buffer.toString();
        _scrollToBottom();
      }

      HapticFeedback.selectionClick();
    } on OpenAIException catch (e) {
      hasError.value = true;
      messages.add(ChatMessage.assistant('⚠️ ${e.message}'));
    } catch (e) {
      hasError.value = true;
      messages.add(ChatMessage.assistant('⚠️ Could not analyze the image. Please try again.'));
    } finally {
      isLoading.value = false;
      isStreaming.value = false;
      _saveChatHistory();
      _scrollToBottom();
    }
  }


  Future<void> startListening() async {
    if (!speechAvailable.value) {
      Get.snackbar('Voice Unavailable', 'Speech recognition is not available on this device.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    HapticFeedback.mediumImpact();
    isListening.value = true;

    await _speech.listen(
      onResult: (result) {
        textController.text = result.recognizedWords;
        if (result.finalResult) {
          isListening.value = false;
          if (textController.text.trim().isNotEmpty) {
            sendMessage();
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: language.value == 'Hindi' ? 'hi_IN' : 'en_US',
    );
  }

  void stopListening() {
    _speech.stop();
    isListening.value = false;
  }

  bool _handleLanguageSwitch(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('switch to hindi') ||
        lowerText.contains('hindi mein') ||
        lowerText.contains('🗣️ switch to hindi')) {
      switchLanguage('Hindi');
      return true;
    }
    if (lowerText.contains('switch to english') ||
        lowerText.contains('english mein') ||
        lowerText.contains('🗣️ switch to english')) {
      switchLanguage('English');
      return true;
    }
    return false;
  }

  void switchLanguage(String lang) {
    language.value = lang;
    _storage.write(_langKey, lang);
    _updateSystemPrompt();

    HapticFeedback.selectionClick();
    messages.add(ChatMessage.assistant(
      lang == 'Hindi'
          ? '🗣️ Language Hindi mein switch ho gaya hai! Ab main Hinglish mein jawab dunga. Kya madad chahiye?'
          : '🗣️ Language switched to English! How can I help you?',
    ));
    _saveChatHistory();
    _scrollToBottom();
  }

  void _updateSystemPrompt() {
    // Replace the first system message with updated prompt
    if (messages.isNotEmpty && messages.first.role == MessageRole.system) {
      messages[0] = ChatMessage.system(_systemPrompt);
    }
  }


  void sendSuggestion(String text) => sendMessage(text);

  /// Navigate to report issue page (for chat-to-report flow).
  void openReportIssuePage() {
    Get.toNamed(AppRoutes.reportIssue);
  }


  /// Called externally when a push notification about issue status arrives.
  void addNotificationMessage(String issueTitle, String newStatus) {
    final statusEmoji = switch (newStatus.toLowerCase()) {
      'assigned' => '📋',
      'in-progress' => '🔧',
      'resolved' => '🎉',
      'rejected' => '❌',
      _ => '📢',
    };

    messages.add(ChatMessage.notification(
      '$statusEmoji **Issue Update!**\n\n'
      'Your report "_${issueTitle}_" has been updated to **${newStatus.replaceAll('-', ' ').toUpperCase()}**.\n\n'
      '${newStatus.toLowerCase() == 'resolved' ? 'Great news! Please rate the resolution in "My Reported Issues". Thank you for making your community better! 👏' : 'We\'ll keep you updated on further progress.'}',
    ));
    _saveChatHistory();
    _scrollToBottom();
  }


  void clearChat() {
    messages.clear();
    showSuggestions.value = true;
    hasError.value = false;
    _addWelcomeMessages();
    _saveChatHistory();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }
}
