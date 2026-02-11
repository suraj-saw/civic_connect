import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/report_issue_controller.dart';

class SubmitButton extends GetView<ReportIssueController> {
  const SubmitButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: controller.isSubmitting.value
              ? null
              : controller.submitIssue,
          child: controller.isSubmitting.value
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
              : const Text('Submit Issue'),
        ),
      );
    });
  }
}