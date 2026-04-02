import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/auth_reporsitory.dart';

enum AdminIssueSortOption {
  newestFirst,
  oldestFirst,
  priorityHighToLow, // duplicateReportCount descending
  priorityLowToHigh, // duplicateReportCount ascending
}

class HomeAdminController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _authRepo = AuthRepository();

  final adminDept = ''.obs;
  final adminEmail = ''.obs;
  final adminName = ''.obs;

  final isLoading = true.obs;
  final isIssuesLoading = true.obs;

  /// Raw issues assigned to this admin's department
  final assignedIssues = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  /// UI-ready filtered + sorted list
  final filteredIssues = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  /// Search + filters (category removed)
  final searchQuery = ''.obs;
  final selectedStatus = 'all'.obs;
  final selectedSort = AdminIssueSortOption.newestFirst.obs;

  final availableStatuses = <String>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _issuesSub;
  StreamSubscription<User?>? _authSub;

  @override
  void onInit() {
    super.onInit();
    _listenToAuth();
    _loadAdminInfo();
  }

  void _listenToAuth() {
    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _issuesSub?.cancel();
        assignedIssues.clear();
        filteredIssues.clear();
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
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        adminDept.value = (data['departmentId'] ?? '').toString();
        adminEmail.value = (data['email'] ?? '').toString();
        adminName.value = (data['name'] ?? '').toString();
        _listenToDeptIssues();
      }
    } catch (_) {
      // Keep silent as existing pattern in project
    } finally {
      isLoading.value = false;
    }
  }

  void _listenToDeptIssues() {
    if (adminDept.value.isEmpty) {
      isIssuesLoading.value = false;
      return;
    }

    isIssuesLoading.value = true;
    _issuesSub?.cancel();

    _issuesSub = _firestore
        .collection('issues')
        .where('assignedToDept', isEqualTo: adminDept.value)
        .snapshots()
        .listen((snapshot) {
      assignedIssues.assignAll(snapshot.docs);
      _rebuildStatusMeta();
      applyFilters();
      isIssuesLoading.value = false;
    }, onError: (_) {
      isIssuesLoading.value = false;
    });
  }

  void _rebuildStatusMeta() {
    final statuses = <String>{};

    for (final doc in assignedIssues) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().trim().toLowerCase();
      if (status.isNotEmpty) statuses.add(status);
    }

    final statusList = statuses.toList()..sort();

    availableStatuses
      ..clear()
      ..addAll(['all', ...statusList]);

    // Guard selected value if currently invalid
    if (!availableStatuses.contains(selectedStatus.value)) {
      selectedStatus.value = 'all';
    }
  }

  void updateSearchQuery(String value) {
    // Store raw value — don't trim on every keystroke (trim only at filter time)
    searchQuery.value = value;
    applyFilters();
  }

  void updateStatus(String value) {
    selectedStatus.value = value;
    applyFilters();
  }

  void updateSort(AdminIssueSortOption option) {
    selectedSort.value = option;
    applyFilters();
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedStatus.value = 'all';
    selectedSort.value = AdminIssueSortOption.newestFirst;
    applyFilters();
  }

  /// Whether any non-default filter is active (used for UI badge)
  bool get hasActiveFilters =>
      searchQuery.value.trim().isNotEmpty ||
      selectedStatus.value != 'all' ||
      selectedSort.value != AdminIssueSortOption.newestFirst;

  void applyFilters() {
    final q = searchQuery.value.trim().toLowerCase();
    final status = selectedStatus.value;
    final sortOption = selectedSort.value;

    final list = assignedIssues.where((doc) {
      final data = doc.data();
      final issueId = (data['id'] ?? doc.id).toString().toLowerCase();
      final description = (data['description'] ?? '').toString().toLowerCase();
      final categoryId = (data['categoryId'] ?? '').toString().toLowerCase();
      final statusValue = (data['status'] ?? '').toString().toLowerCase();
      final reporterEmail =
          (data['reporterEmail'] ?? '').toString().toLowerCase();
      final location =
          (data['locationName'] ?? data['address'] ?? '').toString().toLowerCase();

      // Status filter
      if (status != 'all' && statusValue != status) return false;

      // Keyword search — matches across multiple fields
      if (q.isNotEmpty) {
        final matches = issueId.contains(q) ||
            description.contains(q) ||
            categoryId.contains(q) ||
            statusValue.contains(q) ||
            reporterEmail.contains(q) ||
            location.contains(q);
        if (!matches) return false;
      }

      return true;
    }).toList();

    int duplicateCount(Map<String, dynamic> d) {
      final val = d['duplicateReportCount'];
      if (val is int) return val;
      if (val is num) return val.toInt();
      return 1;
    }

    DateTime createdAt(Map<String, dynamic> d) {
      final ts = d['createdAt'];
      if (ts is Timestamp) return ts.toDate();
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    list.sort((a, b) {
      final da = a.data();
      final db = b.data();

      switch (sortOption) {
        case AdminIssueSortOption.newestFirst:
          return createdAt(db).compareTo(createdAt(da));
        case AdminIssueSortOption.oldestFirst:
          return createdAt(da).compareTo(createdAt(db));
        case AdminIssueSortOption.priorityHighToLow:
          return duplicateCount(db).compareTo(duplicateCount(da));
        case AdminIssueSortOption.priorityLowToHigh:
          return duplicateCount(da).compareTo(duplicateCount(db));
      }
    });

    filteredIssues.assignAll(list);
  }

  void refreshIssues() => _listenToDeptIssues();

  Future<void> signOut() async {
    try {
      await _authRepo.signOut();
      if (Get.currentRoute != AppRoutes.signIn) {
        Get.offAllNamed(AppRoutes.signIn);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: $e');
    }
  }

  @override
  void onClose() {
    _issuesSub?.cancel();
    _authSub?.cancel();
    super.onClose();
  }
}