import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/auth_reporsitory.dart';

class HomeAdminController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthRepository _authRepository = AuthRepository();

  final RxString adminDept = ''.obs;
  final RxString adminEmail = ''.obs;
  final RxString adminName = ''.obs;
  final RxBool isLoading = true.obs;
  final RxBool isIssuesLoading = true.obs;

  final RxList<QueryDocumentSnapshot<Map<String, dynamic>>> assignedIssues =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _issuesSubscription;
  StreamSubscription<User?>? _authSubscription;

  // Statuses that should NOT appear on the admin dashboard.
  // 'reopened' is intentionally excluded — it must re-appear for the admin.
  static const _hiddenStatuses = {'resolved', 'rejected'};

  @override
  void onInit() {
    super.onInit();
    _listenToAuthChanges();
    _loadAdminInfo();
  }

  void _listenToAuthChanges() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _issuesSubscription?.cancel();
        assignedIssues.clear();
      }
    });
  }

  Future<void> _loadAdminInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        isLoading.value = false;
        return;
      }

      isLoading.value = true;

      final userDoc =
      await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        adminDept.value = data['departmentId'] ?? '';
        adminEmail.value = data['email'] ?? '';
        adminName.value = data['name'] ?? '';
        _listenToDepartmentIssues();
      }
    } catch (e) {
      print('Error loading admin info: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _listenToDepartmentIssues() {
    if (adminDept.value.isEmpty) {
      isIssuesLoading.value = false;
      assignedIssues.clear();
      return;
    }

    isIssuesLoading.value = true;
    _issuesSubscription?.cancel();

    // Firestore does not support "not in" with orderBy on a different field
    // in a single query without a composite index, so we fetch all issues for
    // the department and filter client-side. This is safe because each admin
    // only sees their own department's issues.
    _issuesSubscription = _firestore
        .collection('issues')
        .where('assignedToDept', isEqualTo: adminDept.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        final active = snapshot.docs
            .where((doc) =>
        !_hiddenStatuses.contains(doc.data()['status']?.toString()))
            .toList();
        assignedIssues.assignAll(active);
        isIssuesLoading.value = false;
      },
      onError: (e) {
        // Fallback without orderBy if composite index is missing
        if (e.toString().contains('failed-precondition')) {
          _issuesSubscription?.cancel();
          _issuesSubscription = _firestore
              .collection('issues')
              .where('assignedToDept', isEqualTo: adminDept.value)
              .snapshots()
              .listen(
                (snapshot) {
              final active = snapshot.docs
                  .where((doc) => !_hiddenStatuses
                  .contains(doc.data()['status']?.toString()))
                  .toList();
              assignedIssues.assignAll(active);
              isIssuesLoading.value = false;
            },
            onError: (_) => isIssuesLoading.value = false,
          );
          return;
        }

        if (e.toString().contains('permission-denied')) {
          isIssuesLoading.value = false;
          return;
        }

        print('Assigned issues fetch error: $e');
        isIssuesLoading.value = false;
        Get.snackbar('Error', 'Failed to load department issues',
            snackPosition: SnackPosition.BOTTOM);
      },
    );
  }

  void refreshIssues() => _listenToDepartmentIssues();

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      if (Get.currentRoute != AppRoutes.signIn) {
        Get.offAllNamed(AppRoutes.signIn);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: $e');
    }
  }

  @override
  void onClose() {
    _issuesSubscription?.cancel();
    _authSubscription?.cancel();
    super.onClose();
  }
}