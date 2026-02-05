// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../../../widgets/admin_drawer.dart';
//
// class HomeAdmin extends StatelessWidget {
//   HomeAdmin({super.key});
//
//   final String uid = FirebaseAuth.instance.currentUser!.uid;
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<DocumentSnapshot>(
//       future:
//       FirebaseFirestore.instance.collection('users').doc(uid).get(),
//       builder: (context, userSnapshot) {
//         if (userSnapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         if (userSnapshot.hasError || !userSnapshot.hasData) {
//           return const Scaffold(
//             body: Center(child: Text("Failed to load admin profile")),
//           );
//         }
//
//         final userData =
//         userSnapshot.data!.data() as Map<String, dynamic>;
//         final String adminDept = userData['departmentId'];
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
//             // ⚠️ requires Firestore composite index
//                 .orderBy('createdAt', descending: true)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               // ✅ HANDLE ERRORS (CRITICAL)
//               if (snapshot.hasError) {
//                 return Center(
//                   child: Text(
//                     "Error loading issues:\n${snapshot.error}",
//                     textAlign: TextAlign.center,
//                   ),
//                 );
//               }
//
//               if (snapshot.connectionState ==
//                   ConnectionState.waiting) {
//                 return const Center(
//                   child: CircularProgressIndicator(),
//                 );
//               }
//
//               if (!snapshot.hasData ||
//                   snapshot.data!.docs.isEmpty) {
//                 return const Center(
//                   child: Text("No issues assigned"),
//                 );
//               }
//
//               return ListView.builder(
//                 padding: const EdgeInsets.all(12),
//                 itemCount: snapshot.data!.docs.length,
//                 itemBuilder: (context, index) {
//                   final doc = snapshot.data!.docs[index];
//                   final data =
//                   doc.data() as Map<String, dynamic>;
//
//                   return Card(
//                     elevation: 2,
//                     child: ListTile(
//                       title: Text(
//                         data['description'] ?? '',
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       subtitle: Text(
//                         "Status: ${data['status']}",
//                       ),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.swap_horiz),
//                         onPressed: () {
//                           _showReassignDialog(
//                             context,
//                             doc.id,
//                             adminDept,
//                           );
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   void _showReassignDialog(
//       BuildContext context,
//       String issueId,
//       String currentDept,
//       ) {
//     String selectedDept = currentDept;
//
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Reassign Issue"),
//         content: DropdownButtonFormField<String>(
//           value: selectedDept,
//           items: const [
//             DropdownMenuItem(value: "road", child: Text("Road")),
//             DropdownMenuItem(value: "water", child: Text("Water")),
//             DropdownMenuItem(
//                 value: "electricity",
//                 child: Text("Electricity")),
//           ],
//           onChanged: (value) {
//             selectedDept = value!;
//           },
//           decoration: const InputDecoration(
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               await FirebaseFirestore.instance
//                   .collection('issues')
//                   .doc(issueId)
//                   .update({
//                 "assignedToDept": selectedDept,
//                 "reassignedBy": uid,
//                 "reassignedAt":
//                 FieldValue.serverTimestamp(),
//                 "status": "assigned",
//               });
//
//               Navigator.pop(context);
//             },
//             child: const Text("Confirm"),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/report_issue/issue_category_controller.dart';
import '../../../widgets/admin_drawer.dart';

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

        final user =
        userSnap.data!.data() as Map<String, dynamic>;
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
                return const Center(
                    child: CircularProgressIndicator());
              }

              if (snap.data!.docs.isEmpty) {
                return const Center(
                    child: Text("No issues assigned"));
              }

              return ListView(
                padding: const EdgeInsets.all(12),
                children: snap.data!.docs.map((doc) {
                  final data =
                  doc.data() as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      title: Text(data['description']),
                      subtitle: Text(
                          "Status: ${data['status']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        onPressed: () {
                          _showReassignDialog(
                            context,
                            doc.id,
                            adminDept,
                            adminEmail,
                          );
                        },
                      ),
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

  /* ================= REASSIGN DIALOG ================= */

  void _showReassignDialog(
      BuildContext context,
      String issueId,
      String fromDept,
      String adminEmail,
      ) {
    String selectedDept = fromDept;
    final TextEditingController reasonCtrl =
    TextEditingController();

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
                decoration: const InputDecoration(
                    labelText: "New Department"),
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
                Get.snackbar("Error",
                    "Select a different department");
                return;
              }
              if (reasonCtrl.text.trim().isEmpty) {
                Get.snackbar(
                    "Error", "Reason is required");
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

    final historyRef =
    issueRef.collection('reassignments').doc();

    await FirebaseFirestore.instance.runTransaction((txn) async {
      txn.update(issueRef, {
        "assignedToDept": toDept,
        "status": "assigned",
        "lastReassignedAt":
        FieldValue.serverTimestamp(),
        "lastReassignedBy": uid,
      });

      txn.set(historyRef, {
        "fromDept": fromDept,
        "toDept": toDept,
        "reason": reason,
        "reassignedByUid": uid,
        "reassignedByEmail": adminEmail,
        "reassignedAt":
        FieldValue.serverTimestamp(),
      });
    });

    Get.snackbar("Success", "Issue reassigned");
  }
}

