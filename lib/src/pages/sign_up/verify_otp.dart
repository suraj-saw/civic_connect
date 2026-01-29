import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth/sign_up_controller.dart';

class VerifyOtpPage extends StatelessWidget {
  const VerifyOtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignUpController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text("Verify Code", style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),

              TextField(
                controller: controller.otpController,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: "Enter OTP"),
              ),
              const SizedBox(height: 30),

              Obx(
                    () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.verifyOtp,
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text("Verify"),
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
