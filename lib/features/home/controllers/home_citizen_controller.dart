import 'package:get/get.dart';
import '../../issues/controllers/my_issues_controller.dart';

class HomeCitizenController extends GetxController {
  var currentIndex = 0.obs;
  var showMyIssues = false.obs;

  void changeTabIndex(int index) {
    currentIndex.value = index;
    if (index != 0) showMyIssues.value = false;
  }

  void openMyIssues() {
    currentIndex.value = 0;
    showMyIssues.value = true;
    if (Get.isRegistered<MyIssuesController>()) Get.find<MyIssuesController>().refresh();
  }

  void openDashboardHome() => showMyIssues.value = false;

  void resetToDashboard() { currentIndex.value = 0; showMyIssues.value = false; }

  void refresh() {
    update();
    if (Get.isRegistered<MyIssuesController>()) Get.find<MyIssuesController>().refresh();
  }
}
