import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_citizen_controller.dart';
import '../../issues/pages/my_reported_issues_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeCitizenController>();

    return Obx(() {
      // 🔁 Switch between dashboard home & my issues
      if (homeController.showMyIssues.value) {
        return MyReportedIssuesPage(
          onBack: homeController.openDashboardHome,
        );
      }

      // ===== DASHBOARD HOME =====
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.report),
                label: const Text("Report an Issue"),
                onPressed: () async {
                  final result = await Get.toNamed('/reportIssue');

                  if (result != null) {
                    print('✅ Returned from report issue page');
                    homeController.refresh();
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.list_alt),
                label: const Text("My Reported Issues"),
                onPressed: homeController.openMyIssues,
              ),
            ),
          ],
        ),
      );
    });
  }
}