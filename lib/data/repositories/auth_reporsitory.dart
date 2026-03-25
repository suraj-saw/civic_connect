import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
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
      final doc =
      await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      final doc =
      await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      _deleteControllerSafely<MyIssuesController>();
      _deleteControllerSafely<NotificationController>();

      if (Get.isRegistered<HomeCitizenController>()) {
        try {
          Get.find<HomeCitizenController>().resetToDashboard();
        } catch (_) {}
        Get.delete<HomeCitizenController>(force: true);
      }

      _deleteControllerSafely<HomeAdminController>();
      _deleteControllerSafely<IssueCategoryController>();

      await _firebaseAuth.signOut();
      Get.offAllNamed(AppRoutes.signIn);
    } catch (e) {
      try {
        Get.offAllNamed(AppRoutes.signIn);
      } catch (_) {}
      rethrow;
    }
  }

  void _deleteControllerSafely<T>() {
    if (Get.isRegistered<T>()) {
      try {
        Get.delete<T>(force: true);
      } catch (_) {}
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}