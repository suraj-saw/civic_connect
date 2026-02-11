import 'package:get/get.dart';

import '../controllers/issue_category_controller.dart';
import '../controllers/issue_permission_controller.dart';
import '../controllers/my_issues_controller.dart';
import '../controllers/report_issue_controller.dart';

class IssueBinding extends Bindings {
  @override
  void dependencies() {
    // Controllers
    Get.lazyPut<MyIssuesController>(
          () => MyIssuesController(),
    );

    Get.lazyPut<ReportIssueController>(
          () => ReportIssueController(),
    );

    Get.lazyPut<IssueCategoryController>(
          () => IssueCategoryController(),
    );

    Get.lazyPut<IssuePermissionController>(
          () => IssuePermissionController(),
    );
  }
}