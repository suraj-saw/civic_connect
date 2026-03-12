import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/theme_toggle_button.dart';
import '../../notifications/pages/notification_page.dart';
import '../controllers/home_citizen_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../profile/pages/profile_page.dart';
import 'dashboard_page.dart';
import 'map_page.dart';

class HomeCitizenPage extends StatelessWidget {
  const HomeCitizenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeCitizenController>()
        ? Get.find<HomeCitizenController>()
        : Get.put(HomeCitizenController());

    final notifController = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    final screens = [
      const DashboardPage(),
      const MapPage(),
      ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Civic Connect'),
        centerTitle: true,
        actions: [
          const ThemeToggleButton(),
          Obx(() => _NotificationBell(
            unreadCount: notifController.unreadCount,
            onTap: () => Get.to(() => const NotificationsPage()),
          )),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: screens,
      )),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: controller.currentIndex.value,
        onTap: controller.changeTabIndex,
        selectedItemColor: Colors.blueAccent,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      )),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationBell({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}