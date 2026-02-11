import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/issue_category_controller.dart';
import '../controllers/issue_permission_controller.dart';
import '../controllers/report_issue_controller.dart';
import '../widgets/media_picker_section.dart';
import '../widgets/report_issue_form.dart';
import '../widgets/submit_button.dart';

class ReportIssuePage extends StatelessWidget {
  const ReportIssuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final reportController = Get.find<ReportIssueController>();
    Get.find<IssueCategoryController>();
    final permissionController = Get.find<IssuePermissionController>();

    return Obx(() {
      if (permissionController.isCheckingLocationPermission.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (permissionController.hasLocationPermission &&
          reportController.issueLocation.value == null) {
        reportController.captureCurrentLocation();
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Report Issue')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                if (!permissionController.hasLocationPermission)
                  _buildLocationPermissionBanner(permissionController),
                const SizedBox(height: 10),
                const ReportIssueForm(),
                const SizedBox(height: 24),
                const MediaPickerSection(),
                const SizedBox(height: 30),
                const SubmitButton(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Describe the Issue',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Attach photo, optional media, and details to help your municipality act quickly.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPermissionBanner(
      IssuePermissionController permissionController,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location permission is not enabled. Please enable it for better issue tracking.',
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: permissionController.ensureLocationPermissionOnLoad,
            child: const Text('Enable Location Permission'),
          ),
        ],
      ),
    );
  }
}
