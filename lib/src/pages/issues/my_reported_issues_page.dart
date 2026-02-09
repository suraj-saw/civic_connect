import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/issues/my_issues_controller.dart';

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
        // ===== HEADER =====
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

        // ===== LIST =====
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
                final issue = controller.myIssues[index].data();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    // ✅ FIX: Constrain image size properly
                    leading: issue['imageUrl'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.network(
                          issue['imageUrl'],
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
                                  value: loadingProgress.expectedTotalBytes != null
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
                      issue['categoryId']?.toUpperCase() ?? "UNKNOWN",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(issue['description'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          "Status: ${issue['status']}",
                          style: TextStyle(
                            color: issue['status'] == 'resolved'
                                ? Colors.green
                                : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}