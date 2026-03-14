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
              _Header(cs: cs).animate().fadeIn(duration: 500.ms),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Full Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: ctrl.nameController,
                        decoration: const InputDecoration(hintText: 'John Doe', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                      ).animate().fadeIn(delay: 80.ms).slideX(begin: -0.04),
                      const SizedBox(height: 16),
                      _label('Phone Number'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: ctrl.phoneController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        decoration: const InputDecoration(hintText: '9876543210', prefixIcon: Icon(Icons.phone_outlined), prefixText: '+91 '),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Phone is required';
                          if (v.length != 10) return 'Enter a valid 10-digit number';
                          return null;
                        },
                      ).animate().fadeIn(delay: 120.ms).slideX(begin: -0.04),
                      const SizedBox(height: 16),
                      _label('Email'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: ctrl.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                          return null;
                        },
                      ).animate().fadeIn(delay: 160.ms).slideX(begin: -0.04),
                      const SizedBox(height: 16),
                      _label('Password'),
                      const SizedBox(height: 6),
                      Obx(() => TextFormField(
                        controller: ctrl.passwordController,
                        obscureText: !ctrl.isPasswordVisible.value,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(ctrl.isPasswordVisible.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => ctrl.isPasswordVisible.toggle(),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                      )).animate().fadeIn(delay: 200.ms).slideX(begin: -0.04),
                      const SizedBox(height: 32),
                      Obx(() => SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: ctrl.isLoading.value
                              ? null
                              : () { if (_formKey.currentState!.validate()) ctrl.sendOtp(); },
                          child: ctrl.isLoading.value
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('Create Account'),
                        ),
                      )).animate().fadeIn(delay: 240.ms),
                      const SizedBox(height: 24),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
                            text: 'Already have an account? ',
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
                                recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(AppRoutes.signIn),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 280.ms),
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

  Widget _label(String text) => Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13));
}

class _Header extends StatelessWidget {
  final ColorScheme cs;
  const _Header({required this.cs});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 36),
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
            child: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          Text('Create Account', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Join CivicConnect and make a difference.', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }
}
