import 'package:civic_connect/src/pages/home/admin/home_admin.dart';
import 'package:civic_connect/src/pages/home/citizen/home_citizen.dart';
// import 'package:civic_connect/src/pages/home/home_page.dart';
import 'package:civic_connect/src/pages/sign_up/verify_otp.dart';
import 'package:get/get.dart';
import 'package:civic_connect/src/pages/sign_in/sign_in_page.dart';
import 'package:civic_connect/src/pages/sign_up/sign_up_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.signIn, page: () => SignInPage()),
    GetPage(name: AppRoutes.signUp, page: () => SignUpPage()),
    // GetPage(name: AppRoutes.home, page: () => const HomePage()),
    GetPage(name: AppRoutes.verifyOtp, page: () => const VerifyOtpPage()),
    GetPage(name: AppRoutes.homeAdmin, page: () => const HomeAdmin()),
    GetPage(name: AppRoutes.homeCitizen, page: () => const HomeCitizen()),
  ];
}
