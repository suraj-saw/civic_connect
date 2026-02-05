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
                    leading: issue['imageUrl'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        issue['imageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
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
