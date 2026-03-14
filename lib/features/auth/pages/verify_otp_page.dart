import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/sign_up_controller.dart';

class VerifyOtpPage extends StatelessWidget {
  const VerifyOtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SignUpController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.sms_outlined, size: 44, color: cs.onPrimaryContainer),
              ).animate().scale(begin: const Offset(0.7, 0.7)).fadeIn(),
              const SizedBox(height: 28),
              Text('Verify Your Number', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700), textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 10),
              Text(
                'Enter the 6-digit OTP sent to your phone number.',
                style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 36),
              TextField(
                controller: ctrl.otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 10),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • • • •',
                  hintStyle: GoogleFonts.inter(fontSize: 24, letterSpacing: 8, color: cs.onSurfaceVariant.withOpacity(0.4)),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 32),
              Obx(() => SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: ctrl.isLoading.value ? null : ctrl.verifyOtp,
                  child: ctrl.isLoading.value
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Verify & Create Account'),
                ),
              )).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Resend OTP', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
