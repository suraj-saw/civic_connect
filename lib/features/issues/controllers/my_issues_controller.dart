import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class MyIssuesController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final isLoading = true.obs;
  final myIssues = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;
  final duplicateIssues = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ownSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _dupSub;
  StreamSubscription<User?>? _authSub;

  @override
  void onInit() { super.onInit(); _listenToAuth(); _startListeners(); }

  void _listenToAuth() {
    _authSub = _auth.authStateChanges().listen((user) { if (user == null) _cancelStreams(); });
  }

  void _startListeners() {
    final email = _auth.currentUser?.email;
    if (email == null) { isLoading.value = false; return; }
    _cancelStreams();
    isLoading.value = true;
    bool ownLoaded = false, dupLoaded = false;
    void check() { if (ownLoaded && dupLoaded) isLoading.value = false; }

    _ownSub = _firestore.collection('issues')
        .where('reporterEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((s) { myIssues.assignAll(s.docs); ownLoaded = true; check(); },
        onError: (e) { if (!e.toString().contains('permission-denied')) { ownLoaded = true; check(); } });

    _dupSub = _firestore.collection('issues')
        .where('duplicateReporters', arrayContains: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((s) { duplicateIssues.assignAll(s.docs); dupLoaded = true; check(); },
        onError: (e) { dupLoaded = true; check(); });
  }

  void _cancelStreams() { _ownSub?.cancel(); _dupSub?.cancel(); }
  @override
  void refresh() => _startListeners();

  @override
  void onClose() { _cancelStreams(); _authSub?.cancel(); super.onClose(); }
}
