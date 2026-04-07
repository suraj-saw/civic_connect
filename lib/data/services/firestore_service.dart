import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/issue_constants.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getUserData(String uid) =>
      _firestore.collection('users').doc(uid).get();

  Stream<QuerySnapshot> streamUserIssues(String email) =>
      _firestore
          .collection('issues')
          .where('reporterEmail', isEqualTo: email)
          .orderBy('createdAt', descending: true)
          .snapshots();

  Future<DocumentReference> createIssue(Map<String, dynamic> data) =>
      _firestore.collection('issues').add(data);

  Future<void> updateIssue(String issueId, Map<String, dynamic> data) =>
      _firestore.collection('issues').doc(issueId).update(data);

  Future<QuerySnapshot> getIssuesByCategoryForDuplicateCheck(
    String categoryId,
  ) =>
      _firestore
          .collection('issues')
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('createdAt', descending: true)
          .limit(IssueConstants.duplicateLookupLimit)
          .get();

  Future<void> incrementDuplicateCount({
    required String issueId,
    required int currentCount,
    required List<String> currentReporters,
    required String reporterEmail,
  }) => _firestore.collection('issues').doc(issueId).update({
    'duplicateReportCount': currentCount + 1,
    'duplicateReporters': [...currentReporters, reporterEmail],
  });

  Future<QuerySnapshot> getCategories() =>
      _firestore
          .collection('issue_categories')
          .where('active', isEqualTo: true)
          .orderBy('order')
          .get();

  /// Stream all issues with locations visible to authenticated users
  Stream<QuerySnapshot> getVisibleIssuesStream() =>
      _firestore
          .collection('issues')
          .orderBy('createdAt', descending: true)
          .snapshots();
}
