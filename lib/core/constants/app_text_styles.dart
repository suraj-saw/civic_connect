import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get sectionTitle => GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700);
  static TextStyle get cardLabel    => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey);
  static TextStyle get cardValue    => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle get chipLabel    => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white);
}
