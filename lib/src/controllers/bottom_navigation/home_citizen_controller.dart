import 'package:get/get.dart';
import '../issues/my_issues_controller.dart';

class HomeCitizenController extends GetxController {
  var currentIndex = 0.obs;
  var showMyIssues = false.obs;

  void changeTabIndex(int index) {
    currentIndex.value = index;

    if (index != 0) {
      showMyIssues.value = false;
    }
  }

  void openMyIssues() {
    currentIndex.value = 0;
    showMyIssues.value = true;

    // Refresh data when opening My Issues
    if (Get.isRegistered<MyIssuesController>()) {
      Get.find<MyIssuesController>().refresh();
    }
  }

  void openDashboardHome() {
    showMyIssues.value = false;
  }

  void resetToDashboard() {
    currentIndex.value = 0;
    showMyIssues.value = false;
  }
}