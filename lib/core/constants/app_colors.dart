import 'package:flutter/material.dart';

// class AppColors {
//   static const primary = Color(0xFF2196F3);
//   static const primaryDark = Color(0xFF1976D2);
//   static const secondary = Color(0xFF4CAF50);
//   static const error = Color(0xFFf44336);
//   static const warning = Color(0xFFff9800);
//   static const success = Color(0xFF4caf50);
//   static const info = Color(0xFF2196f3);
//
//   static const background = Color(0xFFFAFAFA);
//   static const surface = Color(0xFFFFFFFF);
//   static const surfaceVariant = Color(0xFFF5F5F5);
//
//   static const textPrimary = Color(0xFF212121);
//   static const textSecondary = Color(0xFF757575);
//   static const textDisabled = Color(0xFFBDBDBD);
//
//   static const divider = Color(0xFFE0E0E0);
// }


class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Status colors
  static const Color statusReported = Color(0xFFFF9800);
  static const Color statusAssigned = Color(0xFF2196F3);
  static const Color statusInProgress = Color(0xFFFFC107);
  static const Color statusResolved = Color(0xFF4CAF50);
  static const Color statusRejected = Color(0xFFF44336);

  // Background colors
  static Color successBackground = Colors.green.shade50;
  static Color errorBackground = Colors.red.shade50;
  static Color warningBackground = Colors.orange.shade50;
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF5F5F5);
  static const divider = Color(0xFFE0E0E0);
}