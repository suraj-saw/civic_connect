import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../home/controllers/home_admin_controller.dart';

class SignInController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;

  /// 🔐 Sign in with role-based navigation
  Future<void> signIn() async {
    isLoading.value = true;

    try {
      // Sign in with Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Fetch user role from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User data not found");
      }

      final role = userDoc.data()?['role'] as String?;

      // Navigate based on role
      if (role == 'admin') {
        Get.offAllNamed(AppRoutes.homeAdmin);
        // Get.delete<HomeAdminController>(force: true);
      } else if (role == 'citizen') {
        Get.offAllNamed(AppRoutes.homeCitizen);
      } else {
        throw Exception("Invalid user role");
      }

    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Sign In Failed",
        e.message ?? "Authentication failed",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[300],
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
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