import 'package:get/get.dart';
import '../controllers/home_citizen_controller.dart';
import '../controllers/home_admin_controller.dart';
import '../../notifications/controllers/notification_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeCitizenController>(() => HomeCitizenController());
    Get.lazyPut<HomeAdminController>(() => HomeAdminController());
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}
