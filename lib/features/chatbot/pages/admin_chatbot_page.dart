import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/admin_chatbot_controller.dart';
import '../models/chat_message_model.dart';
import '../widgets/chat_bubble_widget.dart';
import '../widgets/typing_indicator_widget.dart';

class AdminChatbotPage extends StatelessWidget {
  const AdminChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<AdminChatbotController>()
        ? Get.find<AdminChatbotController>()
        : Get.put(AdminChatbotController());
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2C34) : cs.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Assistant',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                Obx(() => Text(
                      ctrl.isStreaming.value
                          ? 'typing...'
                          : ctrl.isLoading.value
                              ? 'thinking...'
                              : 'online',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontStyle: ctrl.isLoading.value
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    )),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: ctrl.clearChat,
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'New chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
              child: Obx(() {
                final visible = ctrl.messages
                    .where((m) => m.role != MessageRole.system)
                    .toList();
                return ListView.builder(
                  controller: ctrl.scrollController,
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                  itemCount:
                      visible.length + (ctrl.isLoading.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < visible.length) {
                      final msg = visible[index];
                      final isFirst = index == 0 ||
                          visible[index - 1].role != msg.role;
                      final isLast = index == visible.length - 1 ||
                          visible[index + 1].role != msg.role;
                      return ChatBubble(
                        message: msg,
                        isFirstInGroup: isFirst,
                        isLastInGroup: isLast,
                      );
                    }
                    return const TypingIndicator();
                  },
                );
              }),
            ),
          ),
          // Input
          _AdminInputBar(ctrl: ctrl, cs: cs, isDark: isDark),
        ],
      ),
    );
  }
}

class _AdminInputBar extends StatelessWidget {
  final AdminChatbotController ctrl;
  final ColorScheme cs;
  final bool isDark;

  const _AdminInputBar({
    required this.ctrl,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1F2C34) : const Color(0xFFF0F2F5);
    final inputBg = isDark ? const Color(0xFF2A3942) : Colors.white;

    return Container(
      padding: EdgeInsets.only(
        left: 6,
        right: 6,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(color: bgColor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: ctrl.textController,
                focusNode: ctrl.focusNode,
                maxLines: 6,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => ctrl.sendMessage(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF111B21),
                ),
                decoration: InputDecoration(
                  hintText: 'Ask Admin Assistant...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : const Color(0xFF667781),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Obx(() {
            final loading = ctrl.isLoading.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: loading
                      ? (isDark
                          ? const Color(0xFF2A3942)
                          : const Color(0xFFD9D9D9))
                      : cs.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: loading ? null : () => ctrl.sendMessage(),
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white54),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
