import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class SignInController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  Future<void> signIn() async {
    isLoading.value = true;
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) throw Exception("User data not found");

      final role = userDoc.data()?['role'] as String?;

      if (role == 'admin') {
        Get.offAllNamed(AppRoutes.homeAdmin);
      } else if (role == 'citizen') {
        Get.offAllNamed(AppRoutes.homeCitizen);
      } else {
        throw Exception("Invalid user role");
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Sign In Failed", e.message ?? "Authentication failed",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[300]);
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[300]);
    } finally {
      isLoading.value = false;
    }
  }

  void clearFields() {
    emailController.clear();
    passwordController.clear();
    isPasswordVisible.value = false;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
