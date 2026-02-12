//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../controllers/my_issues_controller.dart';
//
// class MyReportedIssuesPage extends StatelessWidget {
//   final VoidCallback? onBack;
//
//   const MyReportedIssuesPage({
//     super.key,
//     this.onBack,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.isRegistered<MyIssuesController>()
//         ? Get.find<MyIssuesController>()
//         : Get.put(MyIssuesController());
//
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: onBack ?? Get.back,
//         ),
//         title: const Text(
//           'My Reported Issues',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         if (controller.myIssues.isEmpty) {
//           return const Center(
//             child: Text('You have not reported any issues yet.'),
//           );
//         }
//
//         return ListView.builder(
//           padding: const EdgeInsets.all(12),
//           itemCount: controller.myIssues.length,
//           itemBuilder: (context, index) {
//             final issue = controller.myIssues[index].data();
//             final imageUrl = issue['imageUrl'] as String?;
//             final imageUrls = issue['imageUrls'] as List<dynamic>?;
//             final previewImageUrl = imageUrl ??
//                 ((imageUrls != null && imageUrls.isNotEmpty)
//                     ? imageUrls.first as String?
//                     : null);
//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               child: ListTile(
//                 leading: previewImageUrl != null
//                     ? ClipRRect(
//                   borderRadius: BorderRadius.circular(6),
//                   child: SizedBox(
//                     width: 50,
//                     height: 50,
//                     child: Image.network(
//                       previewImageUrl,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           color: Colors.grey[300],
//                           child: const Icon(
//                             Icons.broken_image,
//                             color: Colors.grey,
//                           ),
//                         );
//                       },
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return Container(
//                           color: Colors.grey[200],
//                           child: Center(
//                             child: CircularProgressIndicator(
//                               value: loadingProgress.expectedTotalBytes !=
//                                   null
//                                   ? loadingProgress.cumulativeBytesLoaded /
//                                   loadingProgress.expectedTotalBytes!
//                                   : null,
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 )
//                     : const Icon(Icons.report),
//                 title: Text(
//                   issue['categoryId']?.toUpperCase() ?? 'UNKNOWN',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(issue['description'] ?? ''),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Status: ${issue['status']}',
//                       style: TextStyle(
//                         color: issue['status'] == 'resolved'
//                             ? Colors.green
//                             : Colors.orange,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       }),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/my_issues_controller.dart';
import 'issue_detail_citizen_page.dart';

class MyReportedIssuesPage extends StatelessWidget {
  final VoidCallback? onBack;

  const MyReportedIssuesPage({
    super.key,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<MyIssuesController>()
        ? Get.find<MyIssuesController>()
        : Get.put(MyIssuesController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? Get.back,
        ),
        title: const Text(
          'My Reported Issues',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.myIssues.isEmpty) {
          return const Center(
            child: Text('You have not reported any issues yet.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.myIssues.length,
          itemBuilder: (context, index) {
            final issue = controller.myIssues[index].data();

            final imageUrl = issue['imageUrl'] as String?;
            final imageUrls = issue['imageUrls'] as List<dynamic>?;
            final previewImageUrl = imageUrl ??
                ((imageUrls != null && imageUrls.isNotEmpty)
                    ? imageUrls.first as String?
                    : null);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: previewImageUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.network(
                      previewImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes !=
                                  null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
                    : const Icon(Icons.report),
                title: Text(
                  issue['categoryId']?.toUpperCase() ?? 'UNKNOWN',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue['description'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${issue['status']}',
                      style: TextStyle(
                        color: issue['status'] == 'resolved'
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  final issueId = (issue['id'] ?? controller.myIssues[index].id).toString();
                  Get.to(() => IssueDetailCitizenPage(issueId: issueId));
                },
              ),
            );
          },
        );
      }),
    );
  }
}
