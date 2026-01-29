import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../sign_in/sign_in_page.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ Waiting for Firebase to restore session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!snapshot.hasData) {
          return SignInPage();
        }

        // ✅ Logged in → decide by role
        return const _RoleResolver();
      },
    );
  }
}

class _RoleResolver extends StatelessWidget {
  const _RoleResolver();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future:
      FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Safety fallback
          FirebaseAuth.instance.signOut();
          return SignInPage();
        }

        final role = snapshot.data!.get('role');

        // 🔀 Redirect ONCE
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (role == 'admin') {
            Get.offAllNamed(AppRoutes.homeAdmin);
          } else {
            Get.offAllNamed(AppRoutes.homeCitizen);
          }
        });

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
