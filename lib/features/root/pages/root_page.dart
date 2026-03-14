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

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // Cache the resolved role per uid to avoid re-fetching on every rebuild.
  String? _cachedUid;
  String? _cachedRole;
  bool _fetchingRole = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // While waiting for Firebase to initialize, show a loader.
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _Loader();
        }

        final user = authSnapshot.data;

        // Not logged in → show sign-in.
        if (user == null) {
          _cleanupControllers();
          _cachedUid = null;
          _cachedRole = null;
          return SignInPage();
        }

        // Same user, role already resolved → go straight to home.
        if (_cachedUid == user.uid && _cachedRole != null) {
          return _homeForRole(_cachedRole!);
        }

        // New uid — fetch role once.
        if (!_fetchingRole || _cachedUid != user.uid) {
          _fetchingRole = true;
          _cachedUid = user.uid;
          _fetchRole(user.uid);
        }

        // Show loader while fetching role.
        return const _Loader();
      },
    );
  }

  Future<void> _fetchRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        // Firestore doc missing — sign out cleanly.
        await FirebaseAuth.instance.signOut();
        _cleanupControllers();
        return;
      }

      final role = doc.data()!['role'] as String? ?? 'citizen';

      if (mounted) {
        setState(() {
          _cachedRole = role;
          _fetchingRole = false;
        });
      }
    } catch (e) {
      // Network or permission error — do NOT sign the user out.
      // Just retry on the next build triggered by auth state.
      if (mounted) {
        setState(() { _fetchingRole = false; });
      }
    }
  }

  Widget _homeForRole(String role) {
    if (role == 'admin') return const HomeAdminPage();
    return const HomeCitizenPage();
  }

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

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
