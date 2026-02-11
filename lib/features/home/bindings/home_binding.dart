import 'package:get/get.dart';
import '../controllers/home_admin_controller.dart';
import '../controllers/home_citizen_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Controllers
    Get.lazyPut<HomeCitizenController>(
          () => HomeCitizenController(),
    );

    Get.lazyPut<HomeAdminController>(
          () => HomeAdminController(),
    );
  }
}