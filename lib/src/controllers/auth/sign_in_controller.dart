import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

class SignInController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;

  Future<void> signIn() async {
    isLoading.value = true;

    try {
      final userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        throw Exception("User profile not found");
      }

      final role = doc['role'];

      if (role == 'admin') {
        Get.offAllNamed(AppRoutes.homeAdmin);
      } else {
        Get.offAllNamed(AppRoutes.homeCitizen);
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Sign In Failed", e.message ?? "Authentication failed");
    } finally {
      isLoading.value = false;
    }
  }
}
