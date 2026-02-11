import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class SignInController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;

  /// 🔐 Sign in
  Future<void> signIn() async {
    isLoading.value = true;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Navigation happens automatically via auth state listener
      Get.offAllNamed(AppRoutes.homeCitizen);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Sign In Failed",
        e.message ?? "Authentication failed",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[300],
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 🧹 Clear fields (CALL THIS ON LOGOUT)
  void clearFields() {
    emailController.clear();
    passwordController.clear();
  }

  /// ♻️ Dispose controllers properly
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}