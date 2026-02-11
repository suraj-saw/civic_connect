import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/sign_in_controller.dart';
import '../../home/controllers/home_admin_controller.dart';
import '../../home/controllers/home_citizen_controller.dart';
import '../../issues/controllers/issue_category_controller.dart';
import '../../issues/controllers/my_issues_controller.dart';
import '../../auth/pages/sign_in_page.dart';
import '../../home/pages/home_citizen_page.dart';
import '../../home/pages/home_admin.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        // 🔄 Waiting for Firebase auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in → show SignInPage
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          _cleanupControllers();
          return  SignInPage();
        }

        // ✅ Logged in → Fetch user role
        final uid = authSnapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get(),
          builder: (context, userSnapshot) {

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 🔥 If permission denied or error → force logout cleanly
            if (userSnapshot.hasError) {
              FirebaseAuth.instance.signOut();
              _cleanupControllers();
              return SignInPage();
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              FirebaseAuth.instance.signOut();
              _cleanupControllers();
              return SignInPage();
            }

            final userData =
            userSnapshot.data!.data() as Map<String, dynamic>?;

            if (userData == null) {
              FirebaseAuth.instance.signOut();
              _cleanupControllers();
              return SignInPage();
            }

            final role = userData['role'] as String?;

            // 👇 IMPORTANT: Controllers are registered inside pages now
            if (role == 'admin') {
              return const HomeAdminPage();
            } else {
              return const HomeCitizenPage();
            }
          },
        );
      },
    );
  }

  /// 🧹 Clean up all auth-dependent controllers
  void _cleanupControllers() {
    if (Get.isRegistered<HomeAdminController>()) {
      Get.delete<HomeAdminController>(force: true);
    }

    if (Get.isRegistered<HomeCitizenController>()) {
      Get.delete<HomeCitizenController>(force: true);
    }

    if (Get.isRegistered<MyIssuesController>()) {
      Get.delete<MyIssuesController>(force: true);
    }

    if (Get.isRegistered<IssueCategoryController>()) {
      Get.delete<IssueCategoryController>(force: true);
    }

    if (Get.isRegistered<SignInController>()) {
      Get.delete<SignInController>(force: true);
    }
  }
}
