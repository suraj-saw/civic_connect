import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum AppSnackbarType { success, error, warning, info }

class AppSnackbar {
  static void show(
    String title,
    String message, {
    AppSnackbarType? type,
    Duration? duration,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Color? backgroundColor,
    Color? colorText,
  }) {
    final context = Get.context ?? Get.overlayContext;
    if (context == null) return;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedType = type ?? _inferType(title: title, message: message);
    final base = _baseColor(cs, resolvedType);

    final resolvedBackground =
      backgroundColor != null
        ? Color.alphaBlend(
          backgroundColor.withValues(alpha: isDark ? 0.36 : 0.18),
          cs.surface,
        )
        : Color.alphaBlend(
          base.withValues(alpha: isDark ? 0.22 : 0.12),
          cs.surface,
        );
    final autoTextColor =
      ThemeData.estimateBrightnessForColor(resolvedBackground) ==
          Brightness.dark
        ? Colors.white
        : const Color(0xFF111111);

    final containerColor =
      resolvedBackground;
    final borderColor = base.withValues(alpha: isDark ? 0.55 : 0.35);
    final textColor = colorText ?? autoTextColor;
    final subTextColor =
      colorText != null
        ? colorText.withValues(alpha: 0.86)
        : autoTextColor.withValues(alpha: 0.82);

    Get.closeAllSnackbars();
    Get.rawSnackbar(
      snackStyle: SnackStyle.FLOATING,
      snackPosition: snackPosition,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      borderRadius: 16,
      borderColor: borderColor,
      borderWidth: 1,
      backgroundColor: containerColor,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      animationDuration: const Duration(milliseconds: 260),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      shouldIconPulse: false,
      messageText: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: base.withValues(alpha: isDark ? 0.28 : 0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_iconForType(resolvedType), color: base, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    );
  }

  static AppSnackbarType _inferType({
    required String title,
    required String message,
  }) {
    final combined = '${title.toLowerCase()} ${message.toLowerCase()}';
    if (combined.contains('error') ||
        combined.contains('failed') ||
        combined.contains('denied') ||
        combined.contains('unavailable')) {
      return AppSnackbarType.error;
    }
    if (combined.contains('success') ||
        combined.contains('updated') ||
        combined.contains('resolved') ||
        combined.contains('thank') ||
        combined.contains('sent') ||
        combined.contains('created')) {
      return AppSnackbarType.success;
    }
    if (combined.contains('required') ||
        combined.contains('warning') ||
        combined.contains('permission') ||
        combined.contains('photo')) {
      return AppSnackbarType.warning;
    }
    return AppSnackbarType.info;
  }

  static Color _baseColor(ColorScheme cs, AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return const Color(0xFF2E7D32);
      case AppSnackbarType.error:
        return cs.error;
      case AppSnackbarType.warning:
        return const Color(0xFFF57C00);
      case AppSnackbarType.info:
        return cs.primary;
    }
  }

  static IconData _iconForType(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return Icons.check_circle_rounded;
      case AppSnackbarType.error:
        return Icons.error_rounded;
      case AppSnackbarType.warning:
        return Icons.warning_amber_rounded;
      case AppSnackbarType.info:
        return Icons.info_rounded;
    }
  }
}
