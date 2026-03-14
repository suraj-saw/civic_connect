import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
    Get.find<IssueCategoryController>();
    final permCtrl = Get.find<IssuePermissionController>();
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      if (permCtrl.isCheckingLocationPermission.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Report Issue')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.report_problem_outlined, color: cs.primary, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Describe the Issue', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: cs.onSurface)),
                            const SizedBox(height: 4),
                            Text('Attach a photo and location to help your municipality act quickly.',
                                style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),
                const ReportIssueForm().animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),
                const MediaPickerSection().animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 32),
                const SubmitButton().animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ),
      );
    });
  }
}
