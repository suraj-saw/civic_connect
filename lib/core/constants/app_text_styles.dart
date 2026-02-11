import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get sectionTitle => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static TextStyle get cardLabel => const TextStyle(
    color: Colors.grey,
    fontSize: 14,
  );

  static TextStyle get cardValue => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get chipLabel => const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );
}