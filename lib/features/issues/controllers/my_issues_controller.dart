import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class MyIssuesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = true.obs;

  // Issues the user originally reported
  final RxList<QueryDocumentSnapshot<Map<String, dynamic>>> myIssues =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  // Issues the user marked as duplicate (reported by someone else)
  final RxList<QueryDocumentSnapshot<Map<String, dynamic>>> duplicateIssues =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ownSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _duplicateSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToAuthChanges();
    _startListeners();
  }

  void _listenToAuthChanges() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user == null) _cancelStreams();
    });
  }

  void _startListeners() {
    final email = _auth.currentUser?.email;
    if (email == null) {
      isLoading.value = false;
      return;
    }

    _cancelStreams();
    isLoading.value = true;

    // Track how many streams have resolved at least once
    bool ownLoaded = false;
    bool dupLoaded = false;

    void checkBothLoaded() {
      if (ownLoaded && dupLoaded) isLoading.value = false;
    }

    _ownSubscription = _firestore
        .collection('issues')
        .where('reporterEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        myIssues.assignAll(snapshot.docs);
        ownLoaded = true;
        checkBothLoaded();
      },
      onError: _handleError,
    );

    _duplicateSubscription = _firestore
        .collection('issues')
        .where('duplicateReporters', arrayContains: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        duplicateIssues.assignAll(snapshot.docs);
        dupLoaded = true;
        checkBothLoaded();
      },
      onError: _handleError,
    );
  }

  void _handleError(dynamic e) {
    if (e.toString().contains('permission-denied')) return;
    Get.snackbar('Error', 'Failed to load your issues',
        snackPosition: SnackPosition.BOTTOM);
    isLoading.value = false;
  }

  void _cancelStreams() {
    _ownSubscription?.cancel();
    _duplicateSubscription?.cancel();
  }

  void refresh() => _startListeners();

  @override
  void onClose() {
    _cancelStreams();
    _authSubscription?.cancel();
    super.onClose();
  }
}