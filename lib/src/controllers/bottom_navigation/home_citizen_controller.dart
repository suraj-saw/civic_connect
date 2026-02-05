
import 'package:get/get.dart';

// class HomeCitizenController extends GetxController {
//   var currentIndex = 0.obs;
//
//   void changeTabIndex(int index) {
//     currentIndex.value = index;
//   }
// }

import 'package:get/get.dart';

class HomeCitizenController extends GetxController {
  var currentIndex = 0.obs;

  // Dashboard sub-view
  var showMyIssues = false.obs;

  void changeTabIndex(int index) {
    currentIndex.value = index;

    // Reset dashboard state when leaving dashboard
    if (index != 0) {
      showMyIssues.value = false;
    }
  }

  void openMyIssues() {
    currentIndex.value = 0; // Dashboard
    showMyIssues.value = true;
  }

  void openDashboardHome() {
    showMyIssues.value = false;
  }

  /// ✅ THIS METHOD WAS MISSING
  void resetToDashboard() {
    currentIndex.value = 0;
    showMyIssues.value = false;
  }
}



