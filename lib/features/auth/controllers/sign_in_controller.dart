import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/routes/app_routes.dart';

class SignInController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  Future<void> signIn() async {
    isLoading.value = true;
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) throw Exception('User data not found');

      final role = userDoc.data()?['role'] as String?;

      if (role == 'admin') {
        Get.offAllNamed(AppRoutes.homeAdmin);
      } else if (role == 'citizen') {
        Get.offAllNamed(AppRoutes.homeCitizen);
      } else {
        throw Exception('Invalid user role');
      }
    } on FirebaseAuthException catch (e) {
      AppSnackbar.show(
        'Sign In Failed',
        e.message ?? 'Authentication failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[300],
      );
    } catch (e) {
      AppSnackbar.show(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[300],
      );
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}