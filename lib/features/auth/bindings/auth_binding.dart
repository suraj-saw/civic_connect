import 'package:get/get.dart';
import '../../../data/repositories/auth_reporsitory.dart';
import '../controllers/sign_in_controller.dart';
import '../controllers/sign_up_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Repository
    Get.lazyPut<AuthRepository>(
          () => AuthRepository(),
    );

    // Controllers
    Get.lazyPut<SignInController>(
          () => SignInController(),
    );

    Get.lazyPut<SignUpController>(
          () => SignUpController(),
    );
  }
}