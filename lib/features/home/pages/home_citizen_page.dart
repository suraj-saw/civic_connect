// import 'package:civic_connect/features/home/pages/dashboard_page.dart';
// import 'package:civic_connect/features/home/pages/map_page.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../issues/controllers/issue_category_controller.dart';
// import '../controllers/home_citizen_controller.dart';
//
// import '../../profile/pages/profile_page.dart';
//
// class HomeCitizenPage extends StatelessWidget {
//   const HomeCitizenPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(HomeCitizenController());
//     final categoryController = Get.put(IssueCategoryController());
//
//     final List<Widget> screens = [
//       const DashboardPage(), // index 0
//       const MapPage(),       // index 1
//       ProfilePage(),         // index 2
//     ];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Civic Connect"),
//         centerTitle: true,
//       ),
//       body: Obx(
//             () => IndexedStack(
//           index: controller.currentIndex.value,
//           children: screens,
//         ),
//       ),
//       bottomNavigationBar: Obx(
//             () => BottomNavigationBar(
//           currentIndex: controller.currentIndex.value,
//           onTap: controller.changeTabIndex,
//           selectedItemColor: Colors.blueAccent,
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.dashboard),
//               label: 'Dashboard',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.map),
//               label: 'Map',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.person),
//               label: 'Profile',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:civic_connect/features/home/pages/dashboard_page.dart';
import 'package:civic_connect/features/home/pages/map_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_citizen_controller.dart';
import '../../profile/pages/profile_page.dart';

class HomeCitizenPage extends StatelessWidget {
  const HomeCitizenPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.find so HomeBinding's lazyPut owns the controller lifecycle.
    // If not yet registered (e.g. direct navigation without binding),
    // fall back to put so the page never crashes.
    final controller = Get.isRegistered<HomeCitizenController>()
        ? Get.find<HomeCitizenController>()
        : Get.put(HomeCitizenController());

    final List<Widget> screens = [
      const DashboardPage(), // index 0
      const MapPage(),       // index 1
      ProfilePage(),         // index 2
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Civic Connect"),
        centerTitle: true,
      ),
      body: Obx(
            () => IndexedStack(
          index: controller.currentIndex.value,
          children: screens,
        ),
      ),
      bottomNavigationBar: Obx(
            () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTabIndex,
          selectedItemColor: Colors.blueAccent,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}