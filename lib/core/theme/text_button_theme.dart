import 'package:flutter/material.dart';

class TTextButtonTheme {
  TTextButtonTheme._();

  static TextButtonThemeData light(ColorScheme scheme) {
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.38)
              : scheme.primary,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
              ? scheme.primary.withValues(alpha: 0.12)
              : null,
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static TextButtonThemeData dark(ColorScheme scheme) => light(scheme);
}
