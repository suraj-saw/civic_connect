import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/services/openai_service.dart';
import '../models/chat_message_model.dart';

class AdminChatbotController extends GetxController {
  final OpenAIService _openAIService = OpenAIService();
  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final _storage = GetStorage();

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isStreaming = false.obs;
  final streamingText = ''.obs;

  String _adminContext = '';
  static const String _storageKey = 'civicbot_admin_history';

  String get _systemPrompt => '''
You are CivicBot Admin Assistant, an AI helper for municipal administrators using the CivicConnect platform.

Your role is to help administrators:
• Understand their issue dashboard and workload
• Triage and prioritize incoming civic issue reports
• Draft response messages to citizens
• Analyze patterns in reported issues (common categories, hotspot areas)
• Suggest efficient resolution strategies
• Understand the admin workflow (Assign → In Progress → Resolve/Reject)

$_adminContext

Guidelines:
- Be concise and action-oriented
- Use markdown formatting for clarity
- Suggest specific actions the admin can take
- Help draft professional citizen-facing responses
- Highlight urgent issues (high duplicate count = many citizens reporting same issue)
- Stay focused on admin/municipal duties
''';

  @override
  void onInit() {
    super.onInit();
    _loadAdminContext();
    _loadHistory();
  }

  @override
  void onClose() {
    scrollController.dispose();
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  Future<void> _loadAdminContext() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get admin's department data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final dept = userDoc.data()?['department'] ?? 'unknown';

      // Get recent issues for this department
      final snapshot = await FirebaseFirestore.instance
          .collection('issues')
          .where('categoryId', isEqualTo: dept)
          .orderBy('createdAt', descending: true)
          .limit(15)
          .get();

      final buffer = StringBuffer();
      buffer.writeln('ADMIN DEPARTMENT: $dept');
      buffer.writeln('TOTAL ISSUES IN VIEW: ${snapshot.docs.length}');

      int reported = 0, assigned = 0, inProgress = 0, resolved = 0;
      for (final doc in snapshot.docs) {
        final d = doc.data();
        final status = (d['status'] ?? 'reported').toString().toLowerCase();
        if (status == 'reported') reported++;
        if (status == 'assigned') assigned++;
        if (status == 'in-progress') inProgress++;
        if (status == 'resolved') resolved++;
      }

      buffer.writeln('STATUS BREAKDOWN: $reported reported, $assigned assigned, $inProgress in-progress, $resolved resolved');
      buffer.writeln('RECENT ISSUES:');
      for (final doc in snapshot.docs.take(8)) {
        final d = doc.data();
        final dupCount = d['duplicateReportCount'] ?? 1;
        buffer.writeln('- "${d['description']?.toString().substring(0, 60) ?? 'N/A'}" | Status: ${d['status']} | Reports: $dupCount');
      }

      _adminContext = buffer.toString();
    } catch (_) {}
  }

  void _loadHistory() {
    final saved = _storage.read<String>(_storageKey);
    if (saved != null) {
      try {
        final list = (jsonDecode(saved) as List)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          messages.addAll(list);
          _scrollToBottom();
          return;
        }
      } catch (_) {}
    }
    _addWelcome();
  }

  void _addWelcome() {
    messages.add(ChatMessage.system(_systemPrompt));
    messages.add(ChatMessage.assistant(
      '👋 Welcome, Admin!\n\n'
      'I\'m your **CivicBot Admin Assistant**. I can help you:\n'
      '• **Triage** — prioritize incoming reports\n'
      '• **Analyze** — spot patterns and hotspots\n'
      '• **Draft** — write citizen response messages\n'
      '• **Strategize** — plan efficient resolution workflows\n\n'
      'What would you like to work on?',
    ));
  }

  void _save() {
    _storage.write(_storageKey, jsonEncode(messages.map((m) => m.toJson()).toList()));
  }

  Future<void> sendMessage([String? override]) async {
    final text = (override ?? textController.text).trim();
    if (text.isEmpty || isLoading.value) return;

    textController.clear();
    HapticFeedback.lightImpact();
    messages.add(ChatMessage.user(text));
    _save();
    _scrollToBottom();

    if (messages.first.role == MessageRole.system) {
      messages[0] = ChatMessage.system(_systemPrompt);
    }

    isLoading.value = true;
    isStreaming.value = true;
    streamingText.value = '';

    try {
      final apiMessages = messages.map((m) => m.toApiMap()).toList();
      messages.add(ChatMessage.assistant(''));

      final buffer = StringBuffer();
      await for (final chunk in _openAIService.streamChatCompletion(apiMessages..removeLast())) {
        buffer.write(chunk);
        messages[messages.length - 1] = ChatMessage.assistant(buffer.toString());
        streamingText.value = buffer.toString();
        _scrollToBottom();
      }
      HapticFeedback.selectionClick();
    } catch (e) {
      final errMsg = e is OpenAIException ? e.message : 'Something went wrong.';
      if (messages.last.content.isEmpty) {
        messages[messages.length - 1] = ChatMessage.assistant('⚠️ $errMsg');
      } else {
        messages.add(ChatMessage.assistant('⚠️ $errMsg'));
      }
    } finally {
      isLoading.value = false;
      isStreaming.value = false;
      _save();
      _scrollToBottom();
    }
  }

  void clearChat() {
    messages.clear();
    _addWelcome();
    _save();
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
