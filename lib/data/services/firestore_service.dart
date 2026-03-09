import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/issue_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── User ────────────────────────────────────────────────────────────────────

  Future<DocumentSnapshot> getUserData(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  // ── Issues ──────────────────────────────────────────────────────────────────

  Future<QuerySnapshot> getAllIssues() {
    return _firestore
        .collection('issues')
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<QuerySnapshot> getUserIssues(String email) {
    return _firestore
        .collection('issues')
        .where('reporterEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<DocumentSnapshot> getIssue(String issueId) {
    return _firestore.collection('issues').doc(issueId).get();
  }

  Stream<QuerySnapshot> streamUserIssues(String email) {
    return _firestore
        .collection('issues')
        .where('reporterEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<DocumentReference> createIssue(Map<String, dynamic> data) {
    return _firestore.collection('issues').add(data);
  }

  Future<void> updateIssue(String issueId, Map<String, dynamic> data) {
    return _firestore.collection('issues').doc(issueId).update(data);
  }

  // ── Duplicate detection ─────────────────────────────────────────────────────

  /// Fetches the most recent issues in [categoryId] for duplicate detection.
  ///
  /// Uses the composite Firestore index:
  ///   issues → categoryId (ASC) + createdAt (DESC) + __name__ (DESC)
  /// which is already enabled in your project (index CICAgOi39lkK).
  Future<QuerySnapshot> getIssuesByCategoryForDuplicateCheck(
      String categoryId) {
    return _firestore
        .collection('issues')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .limit(IssueConstants.duplicateLookupLimit)
        .get();
  }

  /// Bumps `duplicateReportCount` by 1 and appends [reporterEmail] to
  /// `duplicateReporters` on an existing issue document.
  ///
  /// The values written must satisfy the Firestore security rule
  /// `isCitizenDuplicateUpdate()`:
  ///   - new count  == existing count + 1  (or 2 when field was absent)
  ///   - new list   ⊇ existing list  AND  contains the caller's e-mail
  ///   - new list size ≤ existing size + 1
  Future<void> incrementDuplicateCount({
    required String issueId,
    required int currentCount,
    required List<String> currentReporters,
    required String reporterEmail,
  }) {
    return _firestore.collection('issues').doc(issueId).update({
      'duplicateReportCount': currentCount + 1,
      'duplicateReporters': [...currentReporters, reporterEmail],
    });
  }

  // ── Categories ──────────────────────────────────────────────────────────────

  Future<QuerySnapshot> getCategories() {
    return _firestore
        .collection('issue_categories')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .get();
  }

  Stream<QuerySnapshot> streamCategories() {
    return _firestore
        .collection('issue_categories')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .snapshots();
  }
}