import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/sign_in_controller.dart';
import '../../../core/routes/app_routes.dart';

class SignInPage extends StatelessWidget {
  SignInPage({super.key});
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<SignInController>()
        ? Get.find<SignInController>()
        : Get.put(SignInController());
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _HeroHeader(cs: cs).animate().fadeIn(duration: 500.ms),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FieldLabel('Email'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: ctrl.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          final email = v?.trim() ?? '';
                          if (email.isEmpty) return 'Email is required';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Enter a valid email';
                          return null;
                        },
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.04),
                      const SizedBox(height: 20),
                      _FieldLabel('Password'),
                      const SizedBox(height: 6),
                      Obx(() => TextFormField(
                        controller: ctrl.passwordController,
                        obscureText: !ctrl.isPasswordVisible.value,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(ctrl.isPasswordVisible.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => ctrl.isPasswordVisible.toggle(),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                      )).animate().fadeIn(delay: 150.ms).slideX(begin: -0.04),
                      const SizedBox(height: 32),
                      Obx(() => SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: ctrl.isLoading.value
                              ? null
                              : () { if (_formKey.currentState!.validate()) ctrl.signIn(); },
                          child: ctrl.isLoading.value
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('Sign In'),
                        ),
                      )).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 28),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
                            text: "Don't have an account? ",
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
                                recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(AppRoutes.signUp),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final ColorScheme cs;
  const _HeroHeader({required this.cs});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 44),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.35)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          Text('CivicConnect', style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Welcome back! Sign in to continue.', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13));
}