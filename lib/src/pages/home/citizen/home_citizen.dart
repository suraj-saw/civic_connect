import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/bottom_navigation/home_citizen_controller.dart';
import '../../profile/profile_page.dart';
import 'dashboard_page.dart';
import 'map_page.dart';

class HomeCitizen extends StatelessWidget {
  const HomeCitizen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeCitizenController());

    final List<Widget> screens = const [
      DashboardPage(),
      MapPage(),
      ProfilePage(),
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
