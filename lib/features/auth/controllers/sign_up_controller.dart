import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';

class SignUpController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();
  final isPasswordVisible = false.obs;
  final isLoading = false.obs;

  String? _verificationId;

  String get formattedPhone => '+91${phoneController.text.trim()}';

  // ── Duplicate phone check (Firestore query) ──────────────────────────────
  Future<bool> _phoneAlreadyExists() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: formattedPhone)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      Get.snackbar('Error', 'Phone number already registered. Use another.');
      return true;
    }
    return false;
  }

  // ── Send OTP ─────────────────────────────────────────────────────────────
  Future<void> sendOtp() async {
    isLoading.value = true;
    try {
      // No longer swallowing permission-denied — rules now allow this query
      if (await _phoneAlreadyExists()) return;

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          Get.snackbar('Error', e.message ?? 'OTP failed');
        },
        codeSent: (verificationId, _) {
          _verificationId = verificationId;
          Get.toNamed(AppRoutes.verifyOtp);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Unable to send OTP');
    } on FirebaseException catch (e) {
      Get.snackbar('Error', e.message ?? 'Unable to send OTP');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Verify OTP & create account ──────────────────────────────────────────
  Future<void> verifyOtp() async {
    if (_verificationId == null) {
      Get.snackbar('Error', 'OTP session expired. Please go back and retry.');
      return;
    }

    isLoading.value = true;
    UserCredential? emailUserCred;

    try {
      // 1. Build phone credential (no sign-in yet)
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpController.text.trim(),
      );

      // 2. Create the email/password account first → stable UID
      emailUserCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = emailUserCred.user!;

      // 3. Link the verified phone credential to this account
      await user.linkWithCredential(phoneCredential);

      // 4. Write Firestore profile
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': formattedPhone,
        'phoneVerified': true,
        'role': 'citizen',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Success', 'Account created successfully!');
      Get.offAllNamed(AppRoutes.signIn);
    } on FirebaseAuthException catch (e) {
      // If email account was created but linking/Firestore failed, delete it
      // to avoid orphaned auth records
      if (emailUserCred != null) {
        try { await emailUserCred.user?.delete(); } catch (_) {}
      }

      final msg = switch (e.code) {
        'email-already-in-use' => 'Email already registered. Use another.',
        'invalid-verification-code' => 'Invalid OTP. Please try again.',
        'credential-already-in-use' =>
        'Phone number already registered. Use another.',
        _ => e.message ?? 'Verification failed',
      };
      Get.snackbar('Error', msg);
    } on FirebaseException catch (e) {
      if (emailUserCred != null) {
        try { await emailUserCred.user?.delete(); } catch (_) {}
      }
      Get.snackbar('Error', e.message ?? 'Failed to save profile');
    } finally {
      isLoading.value = false;
    }
  }

  void clearFields() {
    isPasswordVisible.value = false;
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();
    otpController.clear();
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