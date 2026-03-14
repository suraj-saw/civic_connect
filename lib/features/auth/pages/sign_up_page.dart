import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/sign_up_controller.dart';
import '../../../core/routes/app_routes.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SignUpController());
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _SignUpHeroHeader(cs: cs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FieldLabel('Full Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: ctrl.nameController,
                        decoration: const InputDecoration(
                          hintText: 'Your full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter required field' : null,
                      ),
                      const SizedBox(height: 18),

                      _FieldLabel('Phone Number'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: ctrl.phoneController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          hintText: '10-digit mobile number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter required field';
                          if (v.length != 10) return 'Enter a valid 10-digit number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

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
                          if (v == null || v.isEmpty) return 'Enter required field';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      _FieldLabel('Password'),
                      const SizedBox(height: 6),
                      Obx(() => TextFormField(
                        controller: ctrl.passwordController,
                        obscureText: !ctrl.isPasswordVisible.value,
                        decoration: InputDecoration(
                          hintText: 'Create a password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(ctrl.isPasswordVisible.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => ctrl.isPasswordVisible.toggle(),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter required field' : null,
                      )),
                      const SizedBox(height: 32),

                      Obx(() => SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: ctrl.isLoading.value
                              ? null
                              : () {
                            if (_formKey.currentState!.validate()) ctrl.sendOtp();
                          },
                          child: ctrl.isLoading.value
                              ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('Send OTP & Continue'),
                        ),
                      )),
                      const SizedBox(height: 28),

                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            text: 'Already have an account? ',
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Get.toNamed(AppRoutes.signIn),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _SignUpHeroHeader extends StatelessWidget {
  final ColorScheme cs;
  const _SignUpHeroHeader({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primary.withBlue(220)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Create Account',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Join CivicConnect and help improve your city.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
    );
  }
}
