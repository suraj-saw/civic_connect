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

  Future<bool> _phoneAlreadyExists() async {
    final existingUser = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: formattedPhone)
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      Get.snackbar(
        'Error',
        'Phone number already exists. Please use another number.',
      );
      return true;
    }

    return false;
  }

  Future<void> sendOtp() async {
    isLoading.value = true;

    try {
      try {
        if (await _phoneAlreadyExists()) {
          return;
        }
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') {
          rethrow;
        }
      }

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

  Future<void> verifyOtp() async {
    if (_verificationId == null) {
      Get.snackbar('Error', 'OTP session expired');
      return;
    }

    isLoading.value = true;

    try {
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpController.text.trim(),
      );

      final phoneUserCred =
      await FirebaseAuth.instance.signInWithCredential(phoneCredential);
      final user = phoneUserCred.user;

      if (user == null) {
        Get.snackbar('Error', 'Unable to verify phone number');
        return;
      }

      final existingProfile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (existingProfile.exists) {
        Get.snackbar(
          'Error',
          'Phone number already exists. Please use another number.',
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      final emailCredential = EmailAuthProvider.credential(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await user.linkWithCredential(emailCredential);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': formattedPhone,
        'phoneVerified': true,
        'role': 'citizen',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Success', 'Account created successfully');
      Get.offAllNamed(AppRoutes.signIn);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        Get.snackbar(
          'Error',
          'Phone number already exists. Please use another number.',
        );
      } else if (e.code == 'email-already-in-use' ||
          e.code == 'credential-already-in-use') {
        Get.snackbar('Error', 'Email already registered. Please use another.');
      } else {
        Get.snackbar('Error', e.message ?? 'OTP verification failed');
      }
    } on FirebaseException catch (e) {
      Get.snackbar('Error', e.message ?? 'Failed to save user profile');
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