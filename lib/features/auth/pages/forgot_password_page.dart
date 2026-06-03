import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available whether navigated via route or directly
    final ctrl = Get.isRegistered<ForgotPasswordController>()
        ? Get.find<ForgotPasswordController>()
        : Get.put(ForgotPasswordController());

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('Forgot Password'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() => ctrl.emailSent.value
            ? _SuccessView(ctrl: ctrl, cs: cs)
            : _FormView(ctrl: ctrl, cs: cs)),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final ForgotPasswordController ctrl;
  final ColorScheme cs;
  const _FormView({required this.ctrl, required this.cs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 44,
                color: cs.primary,
              ),
            ),
          ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(duration: 400.ms),

          const SizedBox(height: 28),

          Text(
            'Reset Your Password',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 10),

          Text(
            'Enter the email address associated with your account and we\'ll send you a link to reset your password.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 36),

          Text(
            'Email Address',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: cs.onSurface,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          TextField(
            controller: ctrl.emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => ctrl.sendPasswordResetEmail(),
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ).animate().fadeIn(delay: 220.ms).slideX(begin: -0.04),

          const SizedBox(height: 32),

          Obx(() => SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed:
              ctrl.isLoading.value ? null : ctrl.sendPasswordResetEmail,
              child: ctrl.isLoading.value
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : const Text('Send Reset Link'),
            ),
          )).animate().fadeIn(delay: 260.ms),

          const SizedBox(height: 20),

          Center(
            child: TextButton.icon(
              onPressed: () => Get.back(),
              icon: Icon(Icons.arrow_back_rounded, size: 16, color: cs.primary),
              label: Text(
                'Back to Sign In',
                style: GoogleFonts.inter(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final ForgotPasswordController ctrl;
  final ColorScheme cs;
  const _SuccessView({required this.ctrl, required this.cs});

  @override
  Widget build(BuildContext context) {
    // Read the email once at build time - no Obx needed since
    // emailController.text is a plain String, not a reactive variable
    final sentToEmail = ctrl.emailController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.38),
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.tertiary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.mark_email_read_rounded,
                size: 52,
                color: cs.tertiary,
              ),
            ),
          ).animate().scale(begin: const Offset(0.6, 0.6)).fadeIn(duration: 500.ms),

          const SizedBox(height: 32),

          Text(
            'Check Your Email',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 12),

          // Plain Text widget - no Obx since sentToEmail is a plain String
          Text(
            'We\'ve sent a password reset link to\n$sentToEmail',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 28),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  text: 'The link will expire in 24 hours.',
                  cs: cs,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.folder_outlined,
                  text:
                  'Check your spam or junk folder if you don\'t see it.',
                  cs: cs,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.devices_rounded,
                  text:
                  'Open the link on any device to reset your password.',
                  cs: cs,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),

          const SizedBox(height: 36),

          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: ctrl.goBackToSignIn,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Back to Sign In'),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () {
                ctrl.emailSent.value = false;
                ctrl.emailController.clear();
              },
              child: Text(
                'Didn\'t receive the email? Try again',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 340.ms),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  const _InfoRow({required this.icon, required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
