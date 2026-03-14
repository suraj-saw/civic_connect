import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sms_outlined, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter the 6-digit code sent to your phone number.',
                        style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Text(
                'Verification Code',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your SMS inbox.',
                style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: ctrl.otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  hintText: '——————',
                  hintStyle: GoogleFonts.inter(letterSpacing: 12, fontSize: 24),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 36),

              Obx(() => SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: ctrl.isLoading.value ? null : ctrl.verifyOtp,
                  child: ctrl.isLoading.value
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Verify & Create Account'),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
