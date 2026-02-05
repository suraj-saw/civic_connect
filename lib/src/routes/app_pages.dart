import 'package:civic_connect/src/controllers/report_issue/issue_permission_controller.dart';
import 'package:civic_connect/src/pages/home/admin/home_admin.dart';
import 'package:civic_connect/src/pages/home/citizen/dashboard_page.dart';
import 'package:civic_connect/src/pages/home/citizen/home_citizen.dart';
import 'package:civic_connect/src/pages/home/citizen/map_page.dart';
import 'package:civic_connect/src/pages/report_issue/report_issue_page.dart';
import 'package:civic_connect/src/pages/sign_up/verify_otp.dart';
import 'package:get/get.dart';
import 'package:civic_connect/src/pages/sign_in/sign_in_page.dart';
import 'package:civic_connect/src/pages/sign_up/sign_up_page.dart';
import '../controllers/report_issue/issue_category_controller.dart';
import '../controllers/report_issue/report_issue_controller.dart';
import '../pages/issues/my_reported_issues_page.dart';
import '../pages/profile/profile_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.signIn, page: () => SignInPage()),
    GetPage(name: AppRoutes.signUp, page: () => SignUpPage()),
    GetPage(name: AppRoutes.verifyOtp, page: () => const VerifyOtpPage()),
    GetPage(name: AppRoutes.homeAdmin, page: () => HomeAdmin()),
    GetPage(name: AppRoutes.homeCitizen, page: () => const HomeCitizen()),
    GetPage(name: AppRoutes.profile, page: () => ProfilePage()),
    GetPage(name: AppRoutes.citizenMap, page: () => const MapPage()),
    GetPage(name: AppRoutes.citizenDashboard, page: () => const DashboardPage()),

    GetPage(name: AppRoutes.reportIssue, page: () => const ReportIssuePage(), binding: BindingsBuilder(() {
      Get.put(IssuePermissionController());
      Get.put(ReportIssueController());
      Get.put(IssueCategoryController());
    } )),


  ];
}
