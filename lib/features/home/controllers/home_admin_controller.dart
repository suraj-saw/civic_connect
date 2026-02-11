import 'package:get/get.dart';

class HomeAdminController extends GetxController {
  var currentIndex = 0.obs;

  void changeTabIndex(int index) {
    currentIndex.value = index;
  }

  void refresh() {
    update();
  }
}