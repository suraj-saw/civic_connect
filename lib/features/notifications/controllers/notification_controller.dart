import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_item.dart';

class NotificationController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final notifications = <NotificationItem>[].obs;
  final isLoading = true.obs;

  // In-memory cache — backed by SharedPreferences.
  final _readIds = <String>{};

  StreamSubscription<QuerySnapshot>? _issuesSubscription;
  StreamSubscription<User?>? _authSubscription;

  // ── Prefs key scoped per user ─────────────────────────────────────────────

  String get _prefsKey {
    final email = _auth.currentUser?.email ?? 'unknown';
    return 'notif_read_ids_$email';
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _listenToAuthChanges();
    _initForCurrentUser();

  }

  Future<void> _initForCurrentUser() async {
    await _loadReadIds();
    _listenToNotifications();
  }

  // ── Auth state ────────────────────────────────────────────────────────────

  void _listenToAuthChanges() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _issuesSubscription?.cancel();
        _issuesSubscription = null;
        notifications.clear();
        _readIds.clear();
        isLoading.value = true;
      } else {
        // New user logged in — load their own read state then start stream.
        await _loadReadIds();
        _listenToNotifications();
      }
    });
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_prefsKey) ?? [];
      _readIds
        ..clear()
        ..addAll(stored);
    } catch (e) {
      debugPrint('[Notifications] Failed to load read IDs: $e');
    }
  }

  Future<void> _saveReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _readIds.toList());
    } catch (e) {
      debugPrint('[Notifications] Failed to save read IDs: $e');
    }
  }

  // ── Firestore stream ──────────────────────────────────────────────────────

  void _listenToNotifications() {
    final email = _auth.currentUser?.email;
    if (email == null) {
      isLoading.value = false;
      return;
    }

    _issuesSubscription?.cancel();
    isLoading.value = true;

    _issuesSubscription = _firestore
        .collection('issues')
        .where('reporterEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      _onIssuesSnapshot,
      onError: (e) {
        if (e.toString().contains('permission-denied')) return;
        isLoading.value = false;
      },
    );
  }

  void _onIssuesSnapshot(QuerySnapshot snapshot) {
    final citizenEmail = _auth.currentUser?.email ?? '';
    final extracted = <NotificationItem>[];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final issueId = doc.id;
      final categoryId = (data['categoryId'] ?? '').toString();
      final rawTimeline = data['timeline'];
      if (rawTimeline == null) continue;

      final timeline = (rawTimeline as List)
          .whereType<Map<String, dynamic>>()
          .toList();

      for (final entry in timeline) {
        final updatedBy = (entry['updatedBy'] ?? '').toString();
        final updatedByEmail = (entry['updatedByEmail'] ?? '').toString();
        // Skip entries authored by the citizen themselves.
        if (updatedBy == citizenEmail || updatedByEmail == citizenEmail) continue;

        final status = (entry['status'] ?? '').toString();
        if (status == 'reported') continue;

        final ts = _parseTimestamp(entry['timestamp']);
        if (ts == null) continue;

        final id = _entryId(issueId, ts);
        extracted.add(NotificationItem(
          issueId: issueId,
          categoryId: categoryId,
          status: status,
          message: (entry['message'] ?? '').toString(),
          timestamp: ts,
          isRead: _readIds.contains(id),
        ));
      }
    }

    extracted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifications.value = extracted;
    isLoading.value = false;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _entryId(String issueId, DateTime timestamp) =>
      '${issueId}_${timestamp.millisecondsSinceEpoch}';

  DateTime? _parseTimestamp(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    return null;
  }

  // ── Read state (public) ───────────────────────────────────────────────────

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> markAllAsRead() async {
    for (final n in notifications) {
      _readIds.add(_entryId(n.issueId, n.timestamp));
    }
    notifications.value =
        notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveReadIds();
  }

  Future<void> markOneAsRead(NotificationItem item) async {
    final id = _entryId(item.issueId, item.timestamp);
    _readIds.add(id);
    final index = notifications
        .indexWhere((n) => _entryId(n.issueId, n.timestamp) == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
    }
    await _saveReadIds();
  }

  @override
  void onClose() {
    _issuesSubscription?.cancel();
    _authSubscription?.cancel();
    super.onClose();
  }
}