import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../root/pages/root_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), _openRoot);
  }

  void _openRoot() {
    if (!mounted) return;
    Get.off(
          () => const RootPage(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primary.withOpacity(isDark ? 0.18 : 0.12),
              cs.surface,
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer.withOpacity(0.58),
                      border: Border.all(
                        color: cs.primary.withOpacity(0.24),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.14),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      size: 66,
                      color: cs.primary,
                    ),
                  )
                      .animate()
                      .scale(duration: 700.ms, curve: Curves.easeOutBack)
                      .fadeIn(duration: 420.ms),
                  const SizedBox(height: 20),
                  Text(
                    'CivicConnect',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      letterSpacing: 0.2,
                    ),
                  ).animate().fadeIn(delay: 180.ms, duration: 450.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Report • Track • Resolve',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                  ).animate().fadeIn(delay: 280.ms, duration: 450.ms),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}