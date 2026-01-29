
import 'package:get/get.dart';

class HomeCitizenController extends GetxController {
  var currentIndex = 0.obs;

  void changeTabIndex(int index) {
    currentIndex.value = index;
  }
}