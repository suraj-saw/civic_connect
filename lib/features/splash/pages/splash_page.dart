import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../auth/pages/sign_in_page.dart';
import '../../home/pages/home_admin.dart';
import '../../home/pages/home_citizen_page.dart';
import '../../../firebase_options.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final result = await Future.wait<dynamic>([
      _resolveInitialPage(),
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);

    if (!mounted) return;

    final nextPage = result.first as Widget;
    Get.offAll(
      () => nextPage,
      transition: Transition.noTransition,
    );
  }

  Future<Widget> _resolveInitialPage() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return SignInPage();
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        await FirebaseAuth.instance.signOut();
        return SignInPage();
      }

      final role = doc.data()!['role'] as String? ?? 'citizen';
      if (role == 'admin') return const HomeAdminPage();
      return const HomeCitizenPage();
    } catch (_) {
      return SignInPage();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primary.withOpacity(0.12),
              cs.surface,
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primaryContainer.withOpacity(0.6),
                    border: Border.all(color: cs.primary.withOpacity(0.25)),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    size: 58,
                    color: cs.primary,
                  ),
                )
                    .animate()
                    .scale(duration: 650.ms, curve: Curves.easeOutBack)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 18),
                Text(
                  'CivicConnect',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  'Report • Track • Resolve',
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                const SizedBox(height: 28),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 350.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}