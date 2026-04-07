import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/chat_message_model.dart';

/// WhatsApp-style chat bubble with markdown rendering, image support, and copy.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const ChatBubble({
    super.key,
    required this.message,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  bool get _isUser => message.role == MessageRole.user;
  bool get _isNotification => message.type == MessageType.notification;
  bool get _isImage => message.type == MessageType.image;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Notification messages get centered special treatment
    if (_isNotification) {
      return _NotificationBubble(message: message, cs: cs, isDark: isDark);
    }

    // Colors
    final userBubbleColor = isDark ? const Color(0xFF005C4B) : cs.primary;
    final botBubbleColor = isDark ? const Color(0xFF1F2C34) : Colors.white;
    final userTextColor = Colors.white;
    final botTextColor = isDark ? Colors.white : const Color(0xFF111B21);
    final timeColor = _isUser
        ? Colors.white.withValues(alpha: 0.7)
        : (isDark
            ? Colors.white.withValues(alpha: 0.5)
            : const Color(0xFF667781));

    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showCopyMenu(context),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: EdgeInsets.only(
            left: _isUser ? 56 : 12,
            right: _isUser ? 12 : 56,
            top: isFirstInGroup ? 6 : 1.5,
            bottom: isLastInGroup ? 6 : 1.5,
          ),
          child: CustomPaint(
            painter: isLastInGroup
                ? _BubbleTailPainter(
                    isUser: _isUser,
                    color: _isUser ? userBubbleColor : botBubbleColor,
                    hasBorder: !_isUser && !isDark,
                  )
                : null,
            child: Container(
              padding: EdgeInsets.only(
                left: !_isUser && isLastInGroup ? 18 : 12,
                right: _isUser && isLastInGroup ? 18 : 12,
                top: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: _isUser ? userBubbleColor : botBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft:
                      Radius.circular(!_isUser && isLastInGroup ? 3 : 12),
                  bottomRight:
                      Radius.circular(_isUser && isLastInGroup ? 3 : 12),
                ),
                border: !_isUser && !isDark
                    ? Border.all(
                        color: const Color(0xFFE8E8E8), width: 0.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bot label
                  if (!_isUser && isFirstInGroup)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'CivicBot',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),

                  // Image (if image message)
                  if (_isImage && message.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        margin: const EdgeInsets.only(bottom: 6),
                        child: message.imageUrl!.startsWith('http')
                            ? Image.network(message.imageUrl!, fit: BoxFit.cover)
                            : Image.file(File(message.imageUrl!), fit: BoxFit.cover),
                      ),
                    ),

                  // Message content (Markdown for bot, plain for user)
                  if (_isUser)
                    _PlainTextContent(
                      text: message.content,
                      color: userTextColor,
                    )
                  else
                    _MarkdownContent(
                      text: message.content,
                      textColor: botTextColor,
                      linkColor: cs.primary,
                      isDark: isDark,
                    ),

                  // Timestamp row
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('h:mm a').format(message.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: timeColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCopyMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Message copied',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Plain text (user messages)
// ─────────────────────────────────────────────────────────
class _PlainTextContent extends StatelessWidget {
  final String text;
  final Color color;
  const _PlainTextContent({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: GoogleFonts.inter(
        fontSize: 14.5,
        height: 1.35,
        color: color,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Markdown rendered text (bot messages)
// ─────────────────────────────────────────────────────────
class _MarkdownContent extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color linkColor;
  final bool isDark;

  const _MarkdownContent({
    required this.text,
    required this.textColor,
    required this.linkColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.inter(
          fontSize: 14.5,
          height: 1.4,
          color: textColor,
        ),
        strong: GoogleFonts.inter(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        em: GoogleFonts.inter(
          fontSize: 14.5,
          fontStyle: FontStyle.italic,
          color: textColor,
        ),
        listBullet: GoogleFonts.inter(
          fontSize: 14.5,
          color: textColor,
        ),
        a: GoogleFonts.inter(
          fontSize: 14.5,
          color: linkColor,
          decoration: TextDecoration.underline,
        ),
        h1: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        h2: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        code: GoogleFonts.firaCode(
          fontSize: 13,
          color: textColor,
          backgroundColor:
              isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        blockSpacing: 8,
        listIndent: 16,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Notification bubble (centered, special style)
// ─────────────────────────────────────────────────────────
class _NotificationBubble extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme cs;
  final bool isDark;

  const _NotificationBubble({
    required this.message,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primaryContainer.withValues(alpha: isDark ? 0.4 : 0.6),
              cs.tertiaryContainer.withValues(alpha: isDark ? 0.3 : 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            MarkdownBody(
              data: message.content,
              selectable: true,
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.4,
                  color: cs.onSurface,
                ),
                strong: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                em: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurface,
                ),
                blockSpacing: 6,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Bubble tail painter
// ─────────────────────────────────────────────────────────
class _BubbleTailPainter extends CustomPainter {
  final bool isUser;
  final Color color;
  final bool hasBorder;

  _BubbleTailPainter({
    required this.isUser,
    required this.color,
    this.hasBorder = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const tailW = 8.0;

    if (isUser) {
      path.moveTo(size.width, size.height - 12);
      path.lineTo(size.width + tailW, size.height - 4);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, size.height - 12);
      path.lineTo(-tailW, size.height - 4);
      path.lineTo(0, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);

    if (hasBorder) {
      final borderPaint = Paint()
        ..color = const Color(0xFFE8E8E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isUser != isUser;
}
