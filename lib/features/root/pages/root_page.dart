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
  String? _cachedUid;
  String? _cachedRole;
  bool _fetchingRole = false;

  bool get _isOnSignUpFlow {
    final route = Get.currentRoute;
    return route == '/signUp' || route == '/verifyOtp';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _Loader();
        }

        final user = authSnapshot.data;

        if (user == null) {
          if (_isOnSignUpFlow) return const _Loader();

          _cleanupControllers();
          _cachedUid = null;
          _cachedRole = null;
          return SignInPage();
        }

        if (_cachedUid == user.uid && _cachedRole != null) {
          return _homeForRole(_cachedRole!);
        }

        if (!_fetchingRole || _cachedUid != user.uid) {
          _fetchingRole = true;
          _cachedUid = user.uid;
          _fetchRole(user.uid);
        }

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
        if (_isOnSignUpFlow) {
          if (mounted) setState(() => _fetchingRole = false);
          return;
        }
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
      if (mounted) setState(() => _fetchingRole = false);
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