class AppRoutes {
  static const String splash = '/';
  static const String signIn = '/signIn';
  static const String signUp = '/signUp';
  static const String verifyOtp = '/verifyOtp';
  static const String forgotPassword = '/forgotPassword';
  static const String homeAdmin = '/homeAdmin';
  static const String homeCitizen = '/homeCitizen';
  static const String profile = '/profile';
  static const String citizenMap = '/citizenMap';
  static const String citizenDashboard = '/citizenDashboard';
  static const String reportIssue = '/reportIssue';
  static const String myIssues = '/myIssues';
  static const String issueDetail = '/issueDetail/:id';

  static Future<dynamic> goToSignIn() => Future.value(signIn);
  static Future<dynamic> goToHomeCitizen() => Future.value(homeCitizen);
  static Future<dynamic> goToHomeAdmin() => Future.value(homeAdmin);
  static Future<dynamic> goToReportIssue() => Future.value(reportIssue);
  static Future<dynamic> goToProfile() => Future.value(profile);
  static Future<dynamic> goToForgotPassword() => Future.value(forgotPassword);
}