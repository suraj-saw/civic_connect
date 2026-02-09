// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../controllers/issues/my_issues_controller.dart';
//
// class MyReportedIssuesPage extends StatelessWidget {
//   final VoidCallback onBack;
//
//   const MyReportedIssuesPage({
//     super.key,
//     required this.onBack,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(MyIssuesController());
//
//     return Column(
//       children: [
//         // ===== HEADER =====
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.arrow_back),
//                 onPressed: onBack,
//               ),
//               const SizedBox(width: 8),
//               const Text(
//                 "My Reported Issues",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         // ===== LIST =====
//         Expanded(
//           child: Obx(() {
//             if (controller.isLoading.value) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             if (controller.myIssues.isEmpty) {
//               return const Center(
//                 child: Text("You have not reported any issues yet."),
//               );
//             }
//
//             return ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: controller.myIssues.length,
//               itemBuilder: (context, index) {
//                 final issue = controller.myIssues[index].data();
//
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   child: ListTile(
//                     // ✅ FIX: Constrain image size properly
//                     leading: issue['imageUrl'] != null
//                         ? ClipRRect(
//                       borderRadius: BorderRadius.circular(6),
//                       child: SizedBox(
//                         width: 50,
//                         height: 50,
//                         child: Image.network(
//                           issue['imageUrl'],
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return Container(
//                               color: Colors.grey[300],
//                               child: const Icon(
//                                 Icons.broken_image,
//                                 color: Colors.grey,
//                               ),
//                             );
//                           },
//                           loadingBuilder: (context, child, loadingProgress) {
//                             if (loadingProgress == null) return child;
//                             return Container(
//                               color: Colors.grey[200],
//                               child: Center(
//                                 child: CircularProgressIndicator(
//                                   value: loadingProgress.expectedTotalBytes != null
//                                       ? loadingProgress.cumulativeBytesLoaded /
//                                       loadingProgress.expectedTotalBytes!
//                                       : null,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     )
//                         : const Icon(Icons.report),
//
//                     title: Text(
//                       issue['categoryId']?.toUpperCase() ?? "UNKNOWN",
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(issue['description'] ?? ''),
//                         const SizedBox(height: 4),
//                         Text(
//                           "Status: ${issue['status']}",
//                           style: TextStyle(
//                             color: issue['status'] == 'resolved'
//                                 ? Colors.green
//                                 : Colors.orange,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             );
//           }),
//         ),
//       ],
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../controllers/issues/my_issues_controller.dart';
// import 'issue_detail_citizen_page.dart';
//
// class MyReportedIssuesPage extends StatelessWidget {
//   final VoidCallback onBack;
//
//   const MyReportedIssuesPage({
//     super.key,
//     required this.onBack,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(MyIssuesController());
//
//     return Column(
//       children: [
//         // ===== HEADER =====
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.arrow_back),
//                 onPressed: onBack,
//               ),
//               const SizedBox(width: 8),
//               const Text(
//                 "My Reported Issues",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         // ===== LIST =====
//         Expanded(
//           child: Obx(() {
//             if (controller.isLoading.value) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             if (controller.myIssues.isEmpty) {
//               return const Center(
//                 child: Text("You have not reported any issues yet."),
//               );
//             }
//
//             return ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: controller.myIssues.length,
//               itemBuilder: (context, index) {
//                 final issueDoc = controller.myIssues[index];
//                 final issue = issueDoc.data();
//
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   child: ListTile(
//                     leading: issue['imageUrl'] != null
//                         ? ClipRRect(
//                       borderRadius: BorderRadius.circular(6),
//                       child: Image.network(
//                         issue['imageUrl'],
//                         width: 50,
//                         height: 50,
//                         fit: BoxFit.cover,
//                       ),
//                     )
//                         : const Icon(Icons.report),
//                     title: Text(
//                       issue['categoryId']?.toUpperCase() ?? "UNKNOWN",
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           issue['description'] ?? '',
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           "Status: ${issue['status']?.toUpperCase() ?? 'REPORTED'}",
//                           style: TextStyle(
//                             color: _getStatusColor(issue['status']),
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                     onTap: () {
//                       Get.to(() => IssueDetailCitizenPage(
//                         issueId: issueDoc.id,
//                       ));
//                     },
//                   ),
//                 );
//               },
//             );
//           }),
//         ),
//       ],
//     );
//   }
//
//   Color _getStatusColor(String? status) {
//     switch (status) {
//       case 'resolved':
//         return Colors.green;
//       case 'in_progress':
//         return Colors.orange;
//       case 'assigned':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/issues/my_issues_controller.dart';
import 'issue_detail_citizen_page.dart';

class MyReportedIssuesPage extends StatelessWidget {
  final VoidCallback onBack;

  const MyReportedIssuesPage({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyIssuesController());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              const Text(
                "My Reported Issues",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.myIssues.isEmpty) {
              return const Center(
                child: Text("You have not reported any issues yet."),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.myIssues.length,
              itemBuilder: (context, index) {
                final issueDoc = controller.myIssues[index];
                final issue = issueDoc.data();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: _buildLeading(issue),
                    title: Text(
                      issue['categoryId']?.toUpperCase() ?? "UNKNOWN",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Status: ${issue['status']?.toUpperCase() ?? 'REPORTED'}",
                          style: TextStyle(
                            color: _getStatusColor(issue['status']),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Get.to(() => IssueDetailCitizenPage(
                        issueId: issueDoc.id,
                      ));
                    },
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLeading(Map<String, dynamic> issue) {
    if (issue['imageUrl'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          issue['imageUrl'],
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    }

    final status = issue['status'];
    Color color;
    IconData icon;

    switch (status) {
      case 'resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        color = Colors.orange;
        icon = Icons.construction;
        break;
      case 'assigned':
        color = Colors.blue;
        icon = Icons.assignment;
        break;
      default:
        color = Colors.grey;
        icon = Icons.report;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}