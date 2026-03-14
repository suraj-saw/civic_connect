import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/routes/app_routes.dart';
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
    final ctrl = Get.isRegistered<HomeCitizenController>()
        ? Get.find<HomeCitizenController>()
        : Get.put(HomeCitizenController());
    final notifCtrl = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());
    final cs = Theme.of(context).colorScheme;

    final screens = [const DashboardPage(), const MapPage(), ProfilePage()];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_city_rounded, size: 22, color: cs.primary),
            const SizedBox(width: 8),
            Text('CivicConnect', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        actions: [
          const ThemeToggleButton(),
          Obx(() => _NotifBell(count: notifCtrl.unreadCount, onTap: () => Get.to(() => const NotificationsPage()))),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() => IndexedStack(index: ctrl.currentIndex.value, children: screens)),
      floatingActionButton: Obx(() => ctrl.currentIndex.value == 0
          ? FloatingActionButton.extended(
              heroTag: 'report_fab',
              onPressed: () async {
                final result = await Get.toNamed(AppRoutes.reportIssue);
                if (result == true) ctrl.refresh();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Report Issue'),
            ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn()
          : const SizedBox.shrink()),
      bottomNavigationBar: Obx(() => NavigationBar(
        selectedIndex: ctrl.currentIndex.value,
        onDestinationSelected: ctrl.changeTabIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      )),
    );
  }
}

class _NotifBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotifBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (count > 0)
            Positioned(
              top: -4, right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(count > 99 ? '99+' : '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}
