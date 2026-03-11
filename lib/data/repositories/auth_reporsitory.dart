import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../features/auth/controllers/sign_in_controller.dart';
import '../../features/home/controllers/home_citizen_controller.dart';
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
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (Get.isRegistered<MyIssuesController>()) {
        Get.delete<MyIssuesController>(force: true);
      }
      if (Get.isRegistered<NotificationController>()) {
        Get.delete<NotificationController>(force: true);
      }
      if (Get.isRegistered<HomeCitizenController>()) {
        Get.find<HomeCitizenController>().resetToDashboard();
        Get.delete<HomeCitizenController>(force: true);
      }
      if (Get.isRegistered<SignInController>()) {
        Get.find<SignInController>().clearFields();
      }

      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}