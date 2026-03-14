import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../features/auth/controllers/sign_in_controller.dart';
import '../../features/home/controllers/home_admin_controller.dart';
import '../../features/home/controllers/home_citizen_controller.dart';
import '../../features/issues/controllers/issue_category_controller.dart';
import '../../features/issues/controllers/my_issues_controller.dart';
import '../../features/notifications/controllers/notification_controller.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  bool isUserLoggedIn() => _firebaseAuth.currentUser != null;

  Future<String?> getCurrentUserRole() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  /// Signs the user out, cleans up all controllers, then navigates to sign-in.
  Future<void> signOut() async {
    try {
      // 1. Cancel Firestore streams by deleting controllers BEFORE signing out
      if (Get.isRegistered<MyIssuesController>()) {
        Get.delete<MyIssuesController>(force: true);
      }
      if (Get.isRegistered<NotificationController>()) {
        Get.delete<NotificationController>(force: true);
      }
      if (Get.isRegistered<HomeCitizenController>()) {
        try { Get.find<HomeCitizenController>().resetToDashboard(); } catch (_) {}
        Get.delete<HomeCitizenController>(force: true);
      }
      if (Get.isRegistered<HomeAdminController>()) {
        Get.delete<HomeAdminController>(force: true);
      }
      if (Get.isRegistered<IssueCategoryController>()) {
        Get.delete<IssueCategoryController>(force: true);
      }
      if (Get.isRegistered<SignInController>()) {
        try { Get.find<SignInController>().clearFields(); } catch (_) {}
      }

      // 2. Sign out from Firebase
      await _firebaseAuth.signOut();

      // 3. Navigate to sign-in, clearing the entire navigation stack
      Get.offAllNamed(AppRoutes.signIn);
    } catch (e) {
      // Even if something fails, still attempt navigation
      try { Get.offAllNamed(AppRoutes.signIn); } catch (_) {}
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
