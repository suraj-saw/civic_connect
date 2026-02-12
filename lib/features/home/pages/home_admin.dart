import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../issues/pages/issue_detail_admin_page.dart';
import '../controllers/home_admin_controller.dart';
import '../widgets/admin/admin_drawer.dart';

class HomeAdminPage extends StatelessWidget {
  const HomeAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeAdminController>()
        ? Get.find<HomeAdminController>()
        : Get.put(HomeAdminController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('Admin • ${controller.adminDept.value.toUpperCase()}'),
          centerTitle: true,
        ),
        drawer: const AdminDrawer(),
        body: Obx(() {
          if (controller.isIssuesLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.assignedIssues.isEmpty) {
            return const Center(
              child: Text('No issues assigned to your department'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => controller.refreshIssues(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.assignedIssues.length,
              itemBuilder: (context, index) {
                final issue = controller.assignedIssues[index].data();
                final issueId =
                (issue['id'] ?? controller.assignedIssues[index].id).toString();
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
                          'Status: ${issue['status'] ?? 'reported'}',
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
                      Get.to(
                            () => IssueDetailAdminPage(
                          issueId: issueId,
                          adminDept: controller.adminDept.value,
                          adminEmail: controller.adminEmail.value,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        }),
      );
    });
  }
}
