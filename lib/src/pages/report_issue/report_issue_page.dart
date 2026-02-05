
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/report_issue/issue_permission_controller.dart';
import '../../controllers/report_issue/report_issue_controller.dart';
import '../../controllers/report_issue/issue_category_controller.dart';

class ReportIssuePage extends StatelessWidget {
  const ReportIssuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final permissionController = Get.find<IssuePermissionController>();
    final issueController = Get.find<ReportIssueController>();
    final categoryController = Get.find<IssueCategoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Issue"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /* ===================== PHOTO ===================== */

              Text(
                "Add Photo",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Obx(() {
                final File? image = issueController.selectedImage.value;

                if (image == null) {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Camera"),
                          onPressed: () async {
                            final allowed =
                            await permissionController.requestCamera();
                            if (!allowed) return;

                            await issueController.pickFromCamera();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Gallery"),
                          onPressed: () async {
                            final allowed =
                            await permissionController.requestGallery();
                            if (!allowed) return;

                            await issueController.pickFromGallery();
                          },
                        ),
                      ),
                    ],
                  );
                }

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        image,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon:
                          const Icon(Icons.close, color: Colors.white),
                          onPressed: issueController.removeImage,
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 24),

              /* ===================== DESCRIPTION ===================== */

              Text(
                "Description",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              TextField(
                maxLines: 4,
                onChanged: (value) {
                  issueController.descriptionText.value = value;
                },
                decoration: InputDecoration(
                  hintText: "Describe the issue...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Obx(() {
                final isRecording = issueController.isRecording.value;
                final hasAudio = issueController.recordedAudio.value != null;

                return OutlinedButton.icon(
                  icon: Icon(
                    isRecording
                        ? Icons.stop
                        : hasAudio
                        ? Icons.check_circle
                        : Icons.mic,
                    color: isRecording
                        ? Colors.red
                        : hasAudio
                        ? Colors.green
                        : null,
                  ),
                  label: Text(
                    isRecording
                        ? "Stop Recording"
                        : hasAudio
                        ? "Voice Description Added"
                        : "Add Voice Description",
                  ),
                  onPressed: () async {
                    final allowed =
                    await permissionController.requestMic();
                    if (!allowed) return;

                    if (isRecording) {
                      await issueController.stopRecording();
                    } else {
                      await issueController.startRecording();
                    }
                  },
                );
              }),



              const SizedBox(height: 24),

              /* ===================== CATEGORY ===================== */

              Text(
                "Category",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Obx(() {
                if (categoryController.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  hint: const Text("Select category"),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: categoryController.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    issueController.selectedCategoryId.value =
                        value ?? '';
                  },
                );
              }),

              const SizedBox(height: 36),

              /* ===================== SUBMIT ===================== */

              // Obx(() {
              //   return SizedBox(
              //     width: double.infinity,
              //     child: ElevatedButton.icon(
              //       icon: issueController.isSubmitting.value
              //           ? const SizedBox(
              //         width: 18,
              //         height: 18,
              //         child: CircularProgressIndicator(
              //           strokeWidth: 2,
              //           color: Colors.white,
              //         ),
              //       )
              //           : const Icon(Icons.report),
              //       label: const Text("Report Issue"),
              //       onPressed: issueController.isSubmitting.value
              //           ? null
              //           : issueController.submitIssue,
              //       style: ElevatedButton.styleFrom(
              //         padding:
              //         const EdgeInsets.symmetric(vertical: 14),
              //       ),
              //     ),
              //   );
              // }),

              /* ===================== SUBMIT ===================== */

              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: issueController.isSubmitting.value
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.report),
                    label: const Text("Report Issue"),
                    onPressed: issueController.isSubmitting.value
                        ? null
                        : () async {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null || user.email == null) {
                        Get.snackbar(
                          "Error",
                          "User not logged in",
                        );
                        return;
                      }

                      await issueController.submitIssue(
                        reporterEmail: user.email!,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                );
              }),

            ],
          ),
        ),
      ),
    );
  }
}

