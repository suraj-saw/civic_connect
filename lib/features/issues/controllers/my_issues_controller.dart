import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class MyIssuesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = true.obs;
  final RxList<QueryDocumentSnapshot<Map<String, dynamic>>> myIssues =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _issuesSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToAuthChanges();
    _listenToMyIssues();
  }

  /// Listen for logout and cancel Firestore stream immediately
  void _listenToAuthChanges() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _issuesSubscription?.cancel();
      }
    });
  }

  void _listenToMyIssues() {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      isLoading.value = false;
      return;
    }

    _issuesSubscription?.cancel();

    _issuesSubscription = _firestore
        .collection('issues')
        .where('reporterEmail', isEqualTo: user.email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        myIssues.assignAll(snapshot.docs);
        isLoading.value = false;
      },
      onError: (e) {
        // 🔥 Ignore permission denied during logout
        if (e.toString().contains('permission-denied')) {
          return;
        }

        print("MY ISSUES FETCH ERROR: $e");

        Get.snackbar(
          "Error",
          "Failed to load your issues",
          snackPosition: SnackPosition.BOTTOM,
        );

        isLoading.value = false;
      },
    );
  }

  void refresh() {
    isLoading.value = true;
    _listenToMyIssues();
  }

  @override
  void onClose() {
    _issuesSubscription?.cancel();
    _authSubscription?.cancel();
    super.onClose();
  }
}
