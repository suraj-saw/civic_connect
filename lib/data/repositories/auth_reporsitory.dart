import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../features/auth/controllers/sign_in_controller.dart';
import '../../features/home/controllers/home_citizen_controller.dart';
import '../../features/issues/controllers/my_issues_controller.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _firebaseAuth.currentUser != null;
  }

  // Get current user role
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

  // Get user data
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

  // Sign out with proper cleanup
  Future<void> signOut() async {
    try {
      // Cancel all Firestore listeners and delete controllers BEFORE logout
      if (Get.isRegistered<MyIssuesController>()) {
        Get.delete<MyIssuesController>(force: true);
      }

      if (Get.isRegistered<HomeCitizenController>()) {
        final homeController = Get.find<HomeCitizenController>();
        homeController.resetToDashboard();
        Get.delete<HomeCitizenController>(force: true);
      }

      if (Get.isRegistered<SignInController>()) {
        Get.find<SignInController>().clearFields();
      }

      // Now logout from Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}