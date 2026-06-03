import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/chatbot_controller.dart';
import '../models/chat_message_model.dart';
import '../widgets/chat_bubble_widget.dart';
import '../widgets/typing_indicator_widget.dart';
import '../widgets/voice_input_widget.dart';

class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<ChatbotController>()
        ? Get.find<ChatbotController>()
        : Get.put(ChatbotController());
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _ChatHeader(cs: cs, isDark: isDark, ctrl: ctrl),
        Expanded(
          child: Stack(
            children: [
              _ChatWallpaper(isDark: isDark, cs: cs),
              Obx(() {
                final visibleMessages = ctrl.messages
                    .where((m) => m.role != MessageRole.system)
                    .toList();

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: ctrl.scrollController,
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                        itemCount: visibleMessages.length +
                            (ctrl.isLoading.value ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < visibleMessages.length) {
                            final msg = visibleMessages[index];
                            final isFirst = index == 0 ||
                                visibleMessages[index - 1].role != msg.role;
                            final isLast =
                                index == visibleMessages.length - 1 ||
                                    visibleMessages[index + 1].role != msg.role;
                            return ChatBubble(
                              message: msg,
                              isFirstInGroup: isFirst,
                              isLastInGroup: isLast,
                            );
                          }
                          return const TypingIndicator();
                        },
                      ),
                    ),
                    if (ctrl.showSuggestions.value &&
                        visibleMessages.length <= 2)
                      _SuggestionChips(ctrl: ctrl, cs: cs, isDark: isDark),
                  ],
                );
              }),
            ],
          ),
        ),
        // Input bar or voice overlay
        Obx(() => ctrl.isListening.value
            ? VoiceInputOverlay(
                onStop: ctrl.stopListening,
                isDark: isDark,
              )
            : _ChatInputBar(ctrl: ctrl, cs: cs, isDark: isDark)),
      ],
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  final ChatbotController ctrl;

  const _ChatHeader({
    required this.cs,
    required this.isDark,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34) : cs.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF00A884), const Color(0xFF00D4AA)]
                          : [Colors.white.withValues(alpha: 0.9), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    size: 22,
                    color: isDark ? const Color(0xFF1F2C34) : cs.primary,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2C34) : cs.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CivicBot',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Obx(() {
                    final status = ctrl.isStreaming.value
                        ? 'typing...'
                        : ctrl.isLoading.value
                            ? 'thinking...'
                            : 'online • ${ctrl.language.value}';
                    return Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w400,
                        fontStyle: ctrl.isLoading.value
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Actions
            IconButton(
              onPressed: ctrl.clearChat,
              tooltip: 'New chat',
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 22),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
              onSelected: (val) {
                if (val == 'clear') ctrl.clearChat();
                if (val == 'hindi') ctrl.switchLanguage('Hindi');
                if (val == 'english') ctrl.switchLanguage('English');
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: cs.onSurface),
                      const SizedBox(width: 12),
                      Text('Clear chat',
                          style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: ctrl.language.value == 'Hindi' ? 'english' : 'hindi',
                  child: Row(
                    children: [
                      Icon(Icons.translate_rounded,
                          size: 20, color: cs.onSurface),
                      const SizedBox(width: 12),
                      Text(
                        ctrl.language.value == 'Hindi'
                            ? 'Switch to English'
                            : 'Switch to Hindi',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatWallpaper extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;
  const _ChatWallpaper({required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
      ),
      child: CustomPaint(
        painter: _WallpaperPatternPainter(
          color: isDark
              ? Colors.white.withValues(alpha: 0.02)
              : cs.primary.withValues(alpha: 0.03),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WallpaperPatternPainter extends CustomPainter {
  final Color color;
  _WallpaperPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 60.0;
    const iconSize = 16.0;
    final icons = [_drawCircle, _drawTriangle, _drawSquare, _drawDiamond];

    for (double y = 10; y < size.height; y += spacing) {
      for (double x = 10; x < size.width; x += spacing) {
        final idx = ((x ~/ spacing) + (y ~/ spacing)) % icons.length;
        icons[idx](canvas, Offset(x, y), iconSize, paint);
      }
    }
  }

  void _drawCircle(Canvas c, Offset o, double s, Paint p) =>
      c.drawCircle(o, s / 3, p);

  void _drawTriangle(Canvas c, Offset o, double s, Paint p) {
    c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - s / 3)
          ..lineTo(o.dx - s / 3, o.dy + s / 4)
          ..lineTo(o.dx + s / 3, o.dy + s / 4)
          ..close(),
        p);
  }

  void _drawSquare(Canvas c, Offset o, double s, Paint p) {
    final r = s / 3;
    c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: o, width: r * 2, height: r * 2),
          const Radius.circular(2),
        ),
        p);
  }

  void _drawDiamond(Canvas c, Offset o, double s, Paint p) {
    final r = s / 3;
    c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - r)
          ..lineTo(o.dx + r, o.dy)
          ..lineTo(o.dx, o.dy + r)
          ..lineTo(o.dx - r, o.dy)
          ..close(),
        p);
  }

  @override
  bool shouldRepaint(covariant _WallpaperPatternPainter old) =>
      old.color != color;
}

class _SuggestionChips extends StatelessWidget {
  final ChatbotController ctrl;
  final ColorScheme cs;
  final bool isDark;

  const _SuggestionChips({
    required this.ctrl,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ChatbotController.quickSuggestions.map((text) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => ctrl.sendSuggestion(text),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2C34) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? cs.primary.withValues(alpha: 0.3)
                        : cs.primary.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.15 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : cs.primary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1);
  }
}

class _ChatInputBar extends StatelessWidget {
  final ChatbotController ctrl;
  final ColorScheme cs;
  final bool isDark;

  const _ChatInputBar({
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
          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Camera button
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: IconButton(
                      onPressed: () => _showImageOptions(context),
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : const Color(0xFF667781),
                        size: 23,
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 38, minHeight: 38),
                    ),
                  ),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: ctrl.textController,
                      focusNode: ctrl.focusNode,
                      maxLines: 6,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => ctrl.sendMessage(),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111B21),
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : const Color(0xFF667781),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Send / Mic button
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
                      : const Color(0xFF00A884),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: loading
                        ? null
                        : () {
                            if (ctrl.hasText.value) {
                              ctrl.sendMessage();
                            } else {
                              ctrl.startListening();
                            }
                          },
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: isDark ? Colors.white54 : cs.primary,
                              ),
                            )
                          : Icon(
                              ctrl.hasText.value
                                  ? Icons.send_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
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

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text('Camera', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(ctx);
                ctrl.sendImage(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text('Gallery', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(ctx);
                ctrl.sendImage(source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
