import 'package:civic_connect/features/home/pages/home_admin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../issues/controllers/issue_category_controller.dart';
import '../../auth/pages/sign_in_page.dart';
import '../../home/pages/home_citizen_page.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Register category controller globally (once)
    if (!Get.isRegistered<IssueCategoryController>()) {
      Get.put(IssueCategoryController(), permanent: true);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Waiting for Firebase auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in
        if (!authSnapshot.hasData) {
          return SignInPage();
        }

        // Logged in - fetch user role
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

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return SignInPage();
            }

            final role = userSnapshot.data!.get('role');

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
}