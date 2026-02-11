import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in -> show SignInPage
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          _cleanupControllers();
          return SignInPage();
        }

        final uid = authSnapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If permission denied or invalid user doc -> logout cleanly
            if (userSnapshot.hasError ||
                !userSnapshot.hasData ||
                !userSnapshot.data!.exists) {
              FirebaseAuth.instance.signOut();
              _cleanupControllers();
              return SignInPage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            if (userData == null) {
              FirebaseAuth.instance.signOut();
              _cleanupControllers();
              return SignInPage();
            }

            final role = userData['role'] as String?;

            if (role == 'admin') {
              return const HomeAdminPage();
            }

            return const HomeCitizenPage();
          },
        );
      },
    );
  }

  /// Clean up auth-dependent controllers.
  /// NOTE: SignInController is intentionally NOT deleted here to avoid
  /// disposing TextEditingControllers while SignInPage is rebuilding.
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
  }
}
