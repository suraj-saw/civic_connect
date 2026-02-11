import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../features/auth/controllers/sign_in_controller.dart';
import '../../features/home/controllers/home_citizen_controller.dart';
import '../../features/issues/controllers/my_issues_controller.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _firebaseAuth.currentUser != null;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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