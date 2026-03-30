import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final isLoading = false.obs;
  final emailSent = false.obs;

  Future<void> sendPasswordResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter your email address.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      Get.snackbar(
        'Invalid Email',
        'Please enter a valid email address.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    isLoading.value = true;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      emailSent.value = true;
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'user-not-found' =>
        'No account found with this email address.',
        'invalid-email' => 'The email address is not valid.',
        'too-many-requests' =>
        'Too many attempts. Please try again later.',
        _ => e.message ?? 'Failed to send reset email. Please try again.',
      };
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void goBackToSignIn() {
    Get.offAllNamed(AppRoutes.signIn);
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}