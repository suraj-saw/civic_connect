import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data
  Future<DocumentSnapshot> getUserData(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  // Get all issues
  Future<QuerySnapshot> getAllIssues() {
    return _firestore
        .collection('issues')
        .orderBy('createdAt', descending: true)
        .get();
  }

  // Get user issues
  Future<QuerySnapshot> getUserIssues(String email) {
    return _firestore
        .collection('issues')
        .where('reporterEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .get();
  }

  // Get issue by ID
  Future<DocumentSnapshot> getIssue(String issueId) {
    return _firestore.collection('issues').doc(issueId).get();
  }

  // Stream user issues
  Stream<QuerySnapshot> streamUserIssues(String email) {
    return _firestore
        .collection('issues')
        .where('reporterEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Create issue
  Future<DocumentReference> createIssue(Map<String, dynamic> data) {
    return _firestore.collection('issues').add(data);
  }

  // Update issue
  Future<void> updateIssue(String issueId, Map<String, dynamic> data) {
    return _firestore.collection('issues').doc(issueId).update(data);
  }

  // Get categories
  Future<QuerySnapshot> getCategories() {
    return _firestore
        .collection('issue_categories')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .get();
  }

  // Stream categories
  Stream<QuerySnapshot> streamCategories() {
    return _firestore
        .collection('issue_categories')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .snapshots();
  }
}