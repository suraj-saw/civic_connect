// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
//
// import '../../model/issue_model.dart';
//
// class AdminIssueController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   final String adminDept;
//   AdminIssueController(this.adminDept);
//
//   RxList<IssueModel> issues = <IssueModel>[].obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     fetchIssues();
//   }
//
//   void fetchIssues() {
//     _firestore
//         .collection('issues')
//         .where('assignedToDept', isEqualTo: adminDept)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .listen((snapshot) {
//       issues.value = snapshot.docs
//           .map((doc) => IssueModel.fromFirestore(doc.id, doc.data()))
//           .toList();
//     });
//   }
//
//   Future<void> reassignIssue({
//     required String issueId,
//     required String newDept,
//     required String adminUid,
//   }) async {
//     await _firestore.collection('issues').doc(issueId).update({
//       'assignedToDept': newDept,
//       'reassignedBy': adminUid,
//       'reassignedAt': FieldValue.serverTimestamp(),
//       'status': 'assigned',
//     });
//   }
// }
