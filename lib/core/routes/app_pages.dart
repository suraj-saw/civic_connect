import 'package:civic_connect/features/auth/pages/sign_in_page.dart';
import 'package:civic_connect/features/auth/pages/sign_up_page.dart';
import 'package:civic_connect/features/auth/pages/verify_otp_page.dart';
import 'package:civic_connect/features/auth/bindings/auth_binding.dart';
import 'package:civic_connect/features/home/pages/home_citizen_page.dart';
import 'package:civic_connect/features/home/bindings/home_binding.dart';
import 'package:civic_connect/features/issues/pages/report_issue_page.dart';
import 'package:civic_connect/features/issues/bindings/issue_binding.dart';
import 'package:get/get.dart';
import '../../features/home/pages/home_admin.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    // Auth Routes
    GetPage(
      name: AppRoutes.signIn,
      page: () => SignInPage(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.signUp,
      page: () => SignUpPage(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.verifyOtp,
      page: () => const VerifyOtpPage(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),

    // Home Routes
    GetPage(
      name: AppRoutes.homeCitizen,
      page: () => const HomeCitizenPage(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.homeAdmin,
      page: () => const HomeAdminPage(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),

    // Issue Routes
    GetPage(
      name: AppRoutes.reportIssue,
      page: () => const ReportIssuePage(),
      binding: IssueBinding(),
      // transition: Transition.bottomUp,
    ),
  ];
}