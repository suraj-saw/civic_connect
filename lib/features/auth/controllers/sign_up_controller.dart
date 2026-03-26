import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';

class SignUpController extends GetxController {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController otpController;

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;

  String? _verificationId;

  // Cache form data before any auth operation so it survives
  // controller rebuilds triggered by auth state changes.
  String _cachedName = '';
  String _cachedEmail = '';
  String _cachedPhone = '';
  String _cachedPassword = '';

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    otpController = TextEditingController();
  }

  String get formattedPhone => '+91${phoneController.text.trim()}';

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

  Future<void> sendOtp() async {
    isLoading.value = true;
    try {
      if (await _phoneAlreadyExists()) return;

      // Cache values now before navigation clears them
      _cachedName = nameController.text.trim();
      _cachedEmail = emailController.text.trim();
      _cachedPhone = formattedPhone;
      _cachedPassword = passwordController.text.trim();

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
      Get.snackbar('Error', 'OTP session expired. Please go back and retry.');
      return;
    }

    if (otpController.text.trim().length != 6) {
      Get.snackbar('Error', 'Enter a valid 6-digit OTP.');
      return;
    }

    isLoading.value = true;
    UserCredential? emailUserCred;

    try {
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpController.text.trim(),
      );

      // Step 1: Create email/password account
      emailUserCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _cachedEmail,
        password: _cachedPassword,
      );

      final user = emailUserCred.user!;
      final uid = user.uid;

      // Step 2: Link phone — this may briefly fire sign-out/sign-in
      // auth state events. Capture all needed data before this call.
      await user.linkWithCredential(phoneCredential);

      // Step 3: Wait for auth state to fully settle and token to propagate
      await _waitForAuthToSettle(uid);

      // Step 4: Write Firestore using cached values (controllers may be
      // stale if auth state change triggered a rebuild)
      await _writeUserProfile(uid);

      Get.snackbar('Success', 'Account created successfully!');
      Get.offAllNamed(AppRoutes.signIn);
    } on FirebaseAuthException catch (e) {
      if (emailUserCred != null) {
        try { await emailUserCred.user?.delete(); } catch (_) {}
      }
      Get.snackbar('Error', _authErrorMessage(e.code, e.message));
    } catch (e) {
      if (emailUserCred != null) {
        try { await emailUserCred.user?.delete(); } catch (_) {}
      }
      Get.snackbar('Error', 'Verification failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (_cachedPhone.isEmpty) {
      Get.snackbar('Error', 'Phone number not found. Go back and try again.');
      return;
    }

    isLoading.value = true;
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _cachedPhone,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          Get.snackbar('Error', e.message ?? 'OTP resend failed');
        },
        codeSent: (verificationId, _) {
          _verificationId = verificationId;
          otpController.clear();
          Get.snackbar('OTP Sent', 'A new OTP has been sent to your phone.');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Unable to resend OTP');
    } on FirebaseException catch (e) {
      Get.snackbar('Error', e.message ?? 'Unable to resend OTP');
    } finally {
      isLoading.value = false;
    }
  }

  /// Waits until Firebase Auth confirms the correct user is signed in
  /// and their token is valid. Retries up to 5 seconds.
  Future<void> _waitForAuthToSettle(String expectedUid) async {
    const maxWait = Duration(seconds: 5);
    const interval = Duration(milliseconds: 300);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null && current.uid == expectedUid) {
        // Force token refresh to ensure Firestore rules see valid auth
        try {
          await current.getIdToken(true);
          return;
        } catch (_) {}
      }
      await Future.delayed(interval);
    }

    // Final attempt even if uid didn't match
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      try { await current.getIdToken(true); } catch (_) {}
    }
  }

  Future<void> _writeUserProfile(String uid) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Verify auth is still valid before each attempt
        final current = FirebaseAuth.instance.currentUser;
        if (current == null) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'unauthenticated',
            message: 'User session lost during profile creation.',
          );
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({
          'name': _cachedName,
          'email': _cachedEmail,
          'phone': _cachedPhone,
          'phoneVerified': true,
          'role': 'citizen',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return; // success — exit
      } on FirebaseException catch (e) {
        final isLastAttempt = attempt == maxRetries;
        if (e.code == 'permission-denied' && !isLastAttempt) {
          // Token hasn't propagated to Firestore yet — wait and retry
          await Future.delayed(Duration(milliseconds: 600 * attempt));
          try {
            await FirebaseAuth.instance.currentUser?.getIdToken(true);
          } catch (_) {}
          continue;
        }
        rethrow;
      }
    }
  }

  String _authErrorMessage(String code, String? message) {
    return switch (code) {
      'email-already-in-use' => 'Email already registered. Use another.',
      'invalid-verification-code' => 'Invalid OTP. Please try again.',
      'credential-already-in-use' =>
      'Phone number already registered. Use another.',
      _ => message ?? 'Verification failed',
    };
  }

  void clearFields() {
    try {
      nameController.clear();
      phoneController.clear();
      emailController.clear();
      passwordController.clear();
      otpController.clear();
      isPasswordVisible.value = false;
      _cachedName = '';
      _cachedEmail = '';
      _cachedPhone = '';
      _cachedPassword = '';
    } catch (_) {}
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