import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';

class SignUpController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  final isLoading = false.obs;

  String? _verificationId;

  String get formattedPhone => '+91${phoneController.text.trim()}';

  /// STEP 0: Check Firestore for existing email / phone
  Future<bool> _userAlreadyExists() async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    // Check email
    final emailSnap = await usersRef
        .where('email', isEqualTo: emailController.text.trim())
        .limit(1)
        .get();

    if (emailSnap.docs.isNotEmpty) {
      Get.snackbar("Error", "Email already exists");
      return true;
    }

    // Check phone
    final phoneSnap = await usersRef
        .where('phone', isEqualTo: formattedPhone)
        .limit(1)
        .get();

    if (phoneSnap.docs.isNotEmpty) {
      Get.snackbar("Error", "Phone number already exists");
      return true;
    }

    return false;
  }

  /// STEP 1: Send OTP
  Future<void> sendOtp() async {
    if (await _userAlreadyExists()) return;

    isLoading.value = true;

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          Get.snackbar("Error", e.message ?? "OTP failed");
        },
        codeSent: (verificationId, _) {
          _verificationId = verificationId;
          Get.toNamed(AppRoutes.verifyOtp);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// STEP 2: Verify OTP → create email user → store Firestore
  Future<void> verifyOtp() async {
    if (_verificationId == null) {
      Get.snackbar("Error", "OTP session expired");
      return;
    }

    isLoading.value = true;

    try {
      // Verify phone OTP (TEMPORARY SIGN-IN)
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpController.text.trim(),
      );

      final phoneUserCred =
      await FirebaseAuth.instance.signInWithCredential(phoneCredential);

      // DELETE phone-auth user immediately
      await phoneUserCred.user!.delete();

      // Create email/password auth user ONLY
      final emailUserCred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Store user in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(emailUserCred.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': formattedPhone,
        'phoneVerified': true,
        'role': 'citizen',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar("Success", "Account created successfully");
      Get.offAllNamed(AppRoutes.signIn);
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "OTP verification failed");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
