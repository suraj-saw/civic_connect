import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TAppTheme {
  TAppTheme._();
  static const Color _seed = Color(0xFF1565C0);
  static ThemeData light({Color seedColor = _seed}) {
    final cs = ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light);
    return _build(cs, const Color(0xFFF4F6FB));
  }
  static ThemeData dark({Color seedColor = _seed}) {
    final cs = ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark);
    return _build(cs, const Color(0xFF0D1117));
  }
  static ThemeData _build(ColorScheme cs, Color scaffoldBg) {
    final isDark = cs.brightness == Brightness.dark;
    final base = GoogleFonts.interTextTheme();
    final textTheme = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 15,
        height: 1.38,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.35,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme.apply(bodyColor: cs.onSurface, displayColor: cs.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: cs.outline.withValues(alpha: 0.1),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
        iconTheme: IconThemeData(color: cs.onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: cs.onSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outline.withValues(alpha: isDark ? 0.2 : 0.12)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary, foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary.withValues(alpha: 0.7)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.5 : 0.35),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.error, width: 2)),
        labelStyle: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: cs.onSurfaceVariant.withValues(alpha: 0.55), fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: cs.primary, fontWeight: FontWeight.w500),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
        elevation: 0, height: 64,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: DividerThemeData(color: cs.outline.withValues(alpha: 0.12), thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary, foregroundColor: cs.onPrimary,
        elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Color.alphaBlend(
          cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
          cs.surface,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: cs.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: cs.outline.withValues(alpha: isDark ? 0.55 : 0.35),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      ),
    );
  }
}
