
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../controllers/report_issue/issue_category_controller.dart';
// import '../../../widgets/admin_drawer.dart';
//
// class HomeAdmin extends StatelessWidget {
//   HomeAdmin({super.key});
//
//   final String uid = FirebaseAuth.instance.currentUser!.uid;
//   final IssueCategoryController categoryController =
//   Get.find<IssueCategoryController>();
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<DocumentSnapshot>(
//       future:
//       FirebaseFirestore.instance.collection('users').doc(uid).get(),
//       builder: (context, userSnap) {
//         if (!userSnap.hasData) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         final user =
//         userSnap.data!.data() as Map<String, dynamic>;
//         final adminDept = user['departmentId'];
//         final adminEmail = user['email'];
//
//         return Scaffold(
//           appBar: AppBar(
//             title: Text("Admin • ${adminDept.toUpperCase()}"),
//           ),
//           drawer: AdminDrawer(),
//           body: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('issues')
//                 .where('assignedToDept', isEqualTo: adminDept)
//                 .orderBy('createdAt', descending: true)
//                 .snapshots(),
//             builder: (context, snap) {
//               if (!snap.hasData) {
//                 return const Center(
//                     child: CircularProgressIndicator());
//               }
//
//               if (snap.data!.docs.isEmpty) {
//                 return const Center(
//                     child: Text("No issues assigned"));
//               }
//
//               return ListView(
//                 padding: const EdgeInsets.all(12),
//                 children: snap.data!.docs.map((doc) {
//                   final data =
//                   doc.data() as Map<String, dynamic>;
//
//                   return Card(
//                     child: ListTile(
//                       title: Text(data['description']),
//                       subtitle: Text(
//                           "Status: ${data['status']}"),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.swap_horiz),
//                         onPressed: () {
//                           _showReassignDialog(
//                             context,
//                             doc.id,
//                             adminDept,
//                             adminEmail,
//                           );
//                         },
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   /* ================= REASSIGN DIALOG ================= */
//
//   void _showReassignDialog(
//       BuildContext context,
//       String issueId,
//       String fromDept,
//       String adminEmail,
//       ) {
//     String selectedDept = fromDept;
//     final TextEditingController reasonCtrl =
//     TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Reassign Issue"),
//         content: Obx(() {
//           if (categoryController.isLoading.value) {
//             return const CircularProgressIndicator();
//           }
//
//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               DropdownButtonFormField<String>(
//                 value: selectedDept,
//                 decoration: const InputDecoration(
//                     labelText: "New Department"),
//                 items: categoryController.categories
//                     .map(
//                       (cat) => DropdownMenuItem(
//                     value: cat.id,
//                     child: Text(cat.name),
//                   ),
//                 )
//                     .toList(),
//                 onChanged: (v) => selectedDept = v!,
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: reasonCtrl,
//                 maxLines: 3,
//                 decoration: const InputDecoration(
//                   labelText: "Reason",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ],
//           );
//         }),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             child: const Text("Reassign"),
//             onPressed: () async {
//               if (selectedDept == fromDept) {
//                 Get.snackbar("Error",
//                     "Select a different department");
//                 return;
//               }
//               if (reasonCtrl.text.trim().isEmpty) {
//                 Get.snackbar(
//                     "Error", "Reason is required");
//                 return;
//               }
//
//               await _reassignIssue(
//                 issueId,
//                 fromDept,
//                 selectedDept,
//                 reasonCtrl.text.trim(),
//                 adminEmail,
//               );
//
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   /* ================= CORE LOGIC ================= */
//
//   Future<void> _reassignIssue(
//       String issueId,
//       String fromDept,
//       String toDept,
//       String reason,
//       String adminEmail,
//       ) async {
//     final issueRef =
//     FirebaseFirestore.instance.collection('issues').doc(issueId);
//
//     final historyRef =
//     issueRef.collection('reassignments').doc();
//
//     await FirebaseFirestore.instance.runTransaction((txn) async {
//       txn.update(issueRef, {
//         "assignedToDept": toDept,
//         "status": "assigned",
//         "lastReassignedAt":
//         FieldValue.serverTimestamp(),
//         "lastReassignedBy": uid,
//       });
//
//       txn.set(historyRef, {
//         "fromDept": fromDept,
//         "toDept": toDept,
//         "reason": reason,
//         "reassignedByUid": uid,
//         "reassignedByEmail": adminEmail,
//         "reassignedAt":
//         FieldValue.serverTimestamp(),
//       });
//     });
//
//     Get.snackbar("Success", "Issue reassigned");
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/report_issue/issue_category_controller.dart';
import '../../../widgets/admin_drawer.dart';
import '../../issues/issue_detail_page.dart';

class HomeAdmin extends StatelessWidget {
  HomeAdmin({super.key});

  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final IssueCategoryController categoryController =
  Get.find<IssueCategoryController>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
      FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = userSnap.data!.data() as Map<String, dynamic>;
        final adminDept = user['departmentId'];
        final adminEmail = user['email'];

        return Scaffold(
          appBar: AppBar(
            title: Text("Admin • ${adminDept.toUpperCase()}"),
          ),
          drawer: AdminDrawer(),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('issues')
                .where('assignedToDept', isEqualTo: adminDept)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.data!.docs.isEmpty) {
                return const Center(child: Text("No issues assigned"));
              }

              return ListView(
                padding: const EdgeInsets.all(12),
                children: snap.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(data['status']),
                        child: Icon(
                          _getStatusIcon(data['status']),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        data['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Status: ${data['status']}"),
                          Text(
                            "Category: ${(data['categoryId'] ?? '').toUpperCase()}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.swap_horiz),
                            onPressed: () {
                              _showReassignDialog(
                                context,
                                doc.id,
                                adminDept,
                                adminEmail,
                              );
                            },
                            tooltip: "Reassign",
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () {
                        // Navigate to detail page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                IssueDetailPage(issueId: doc.id),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'reported':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in-progress':
        return Colors.amber;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'reported':
        return Icons.report;
      case 'assigned':
        return Icons.assignment;
      case 'in-progress':
        return Icons.hourglass_bottom;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  /* ================= REASSIGN DIALOG ================= */

  void _showReassignDialog(
      BuildContext context,
      String issueId,
      String fromDept,
      String adminEmail,
      ) {
    String selectedDept = fromDept;
    final TextEditingController reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reassign Issue"),
        content: Obx(() {
          if (categoryController.isLoading.value) {
            return const CircularProgressIndicator();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDept,
                decoration:
                const InputDecoration(labelText: "New Department"),
                items: categoryController.categories
                    .map(
                      (cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                )
                    .toList(),
                onChanged: (v) => selectedDept = v!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Reassign"),
            onPressed: () async {
              if (selectedDept == fromDept) {
                Get.snackbar("Error", "Select a different department");
                return;
              }
              if (reasonCtrl.text.trim().isEmpty) {
                Get.snackbar("Error", "Reason is required");
                return;
              }

              await _reassignIssue(
                issueId,
                fromDept,
                selectedDept,
                reasonCtrl.text.trim(),
                adminEmail,
              );

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /* ================= CORE LOGIC ================= */

  Future<void> _reassignIssue(
      String issueId,
      String fromDept,
      String toDept,
      String reason,
      String adminEmail,
      ) async {
    final issueRef =
    FirebaseFirestore.instance.collection('issues').doc(issueId);

    final historyRef = issueRef.collection('reassignments').doc();

    await FirebaseFirestore.instance.runTransaction((txn) async {
      txn.update(issueRef, {
        "assignedToDept": toDept,
        "status": "assigned",
        "lastReassignedAt": FieldValue.serverTimestamp(),
        "lastReassignedBy": uid,
      });

      txn.set(historyRef, {
        "fromDept": fromDept,
        "toDept": toDept,
        "reason": reason,
        "reassignedByUid": uid,
        "reassignedByEmail": adminEmail,
        "reassignedAt": FieldValue.serverTimestamp(),
      });
    });

    Get.snackbar("Success", "Issue reassigned");
  }
}
