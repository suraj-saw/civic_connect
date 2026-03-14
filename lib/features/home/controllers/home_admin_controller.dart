import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/auth_reporsitory.dart';

class HomeAdminController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _authRepo = AuthRepository();

  final adminDept  = ''.obs;
  final adminEmail = ''.obs;
  final adminName  = ''.obs;
  final isLoading       = true.obs;
  final isIssuesLoading = true.obs;
  final assignedIssues  = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _issuesSub;
  StreamSubscription<User?>? _authSub;

  static const _hiddenStatuses = {'resolved', 'rejected'};

  @override
  void onInit() { super.onInit(); _listenToAuth(); _loadAdminInfo(); }

  void _listenToAuth() {
    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null) { _issuesSub?.cancel(); assignedIssues.clear(); }
    });
  }

  Future<void> _loadAdminInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) { isLoading.value = false; return; }
      isLoading.value = true;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        adminDept.value  = data['departmentId'] ?? '';
        adminEmail.value = data['email'] ?? '';
        adminName.value  = data['name'] ?? '';
        _listenToDeptIssues();
      }
    } catch (_) {} finally { isLoading.value = false; }
  }

  void _listenToDeptIssues() {
    if (adminDept.value.isEmpty) { isIssuesLoading.value = false; return; }
    isIssuesLoading.value = true;
    _issuesSub?.cancel();
    _issuesSub = _firestore.collection('issues')
        .where('assignedToDept', isEqualTo: adminDept.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((s) {
      assignedIssues.assignAll(s.docs.where((d) => !_hiddenStatuses.contains(d.data()['status']?.toString())));
      isIssuesLoading.value = false;
    }, onError: (e) {
      if (e.toString().contains('failed-precondition')) {
        _issuesSub?.cancel();
        _issuesSub = _firestore.collection('issues')
            .where('assignedToDept', isEqualTo: adminDept.value)
            .snapshots()
            .listen((s) {
          assignedIssues.assignAll(s.docs.where((d) => !_hiddenStatuses.contains(d.data()['status']?.toString())));
          isIssuesLoading.value = false;
        }, onError: (_) => isIssuesLoading.value = false);
        return;
      }
      isIssuesLoading.value = false;
    });
  }

  void refreshIssues() => _listenToDeptIssues();

  Future<void> signOut() async {
    try {
      await _authRepo.signOut();
      if (Get.currentRoute != AppRoutes.signIn) Get.offAllNamed(AppRoutes.signIn);
    } catch (e) { Get.snackbar('Error', 'Failed to sign out: $e'); }
  }

  @override
  void onClose() { _issuesSub?.cancel(); _authSub?.cancel(); super.onClose(); }
}
