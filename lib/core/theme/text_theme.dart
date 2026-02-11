import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TTextTheme {
  TTextTheme._();

  static const String _primaryFont = 'Open Sans';
  static const String _headingFont = 'Roboto';

  /// Base TextTheme (NO COLORS HERE)
  static TextTheme baseTextTheme = _buildBaseTextTheme();

  static TextTheme _buildBaseTextTheme() {
    final base = ThemeData(useMaterial3: true).textTheme;

    return base.copyWith(
      // Display (Hero / Large)
      displayLarge: GoogleFonts.getFont(
        _headingFont,
        fontSize: 57,
        fontWeight: FontWeight.bold,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.getFont(
        _headingFont,
        fontSize: 45,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      displaySmall: GoogleFonts.getFont(
        _headingFont,
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),

      // Headline (Page headings)
      headlineLarge: GoogleFonts.getFont(
        _headingFont,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.getFont(
        _headingFont,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineSmall: GoogleFonts.getFont(
        _headingFont,
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),

      // Title (Section titles)
      titleLarge: GoogleFonts.getFont(
        _primaryFont,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleMedium: GoogleFonts.getFont(
        _primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.getFont(
        _primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),

      // Body (Normal text)
      bodyLarge: GoogleFonts.getFont(
        _primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.getFont(
        _primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.getFont(
        _primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),

      // Label (Buttons, chips)
      labelLarge: GoogleFonts.getFont(
        _primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.getFont(
        _primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.getFont(
        _primaryFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
      ),
    );
  }
}
