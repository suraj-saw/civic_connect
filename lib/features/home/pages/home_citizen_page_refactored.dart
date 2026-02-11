// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/home_citizen_controller.dart';
// import '../widgets/citizen/issues_grid_section.dart';
// import '../widgets/citizen/quick_actions_section.dart';
// import '../widgets/citizen/stats_section.dart';
// import '../widgets/common/custom_app_bar.dart';
// import '../widgets/common/navigation_drawer.dart';
//
// class HomeCitizenPage extends GetView<HomeCitizenController> {
//   const HomeCitizenPage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: const NavigationDrawer(),
//       appBar: CustomAppBar(
//         title: 'Civic Connect',
//         onNotificationTap: () => Get.toNamed('/notifications'),
//       ),
//       body: RefreshIndicator(
//         onRefresh: controller.refreshData,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 // Welcome Section
//                 _buildWelcomeSection(),
//                 const SizedBox(height: 24),
//
//                 // Quick Actions
//                 QuickActionsSection(controller: controller),
//                 const SizedBox(height: 24),
//
//                 // Stats Section
//                 StatsSection(controller: controller),
//                 const SizedBox(height: 24),
//
//                 // Your Issues Section
//                 _buildYourIssuesSection(),
//                 const SizedBox(height: 24),
//
//                 // Recent Activity Section
//                 _buildRecentActivitySection(),
//               ],
//             ),
//           ),
//         ),
//       ),
//       bottomNavigationBar: _buildBottomNavBar(),
//     );
//   }
//
//   Widget _buildWelcomeSection() {
//     return Obx(() {
//       final userName = controller.currentUser.value?.name ?? 'Citizen';
//       return Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blue[400]!, Colors.blue[600]!],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Welcome back, $userName! 👋',
//               style: Get.textTheme.headlineSmall?.copyWith(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Help improve your community by reporting issues',
//               style: Get.textTheme.bodyMedium?.copyWith(
//                 color: Colors.white70,
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
//
//   Widget _buildYourIssuesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Your Recent Issues',
//               style: Get.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             GestureDetector(
//               onTap: () => Get.toNamed('/issues'),
//               child: Text(
//                 'See All',
//                 style: Get.textTheme.bodyMedium?.copyWith(
//                   color: Colors.blue[600],
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         IssuesGridSection(controller: controller),
//       ],
//     );
//   }
//
//   Widget _buildRecentActivitySection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Recent Activity',
//           style: Get.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Obx(() {
//           if (controller.recentActivity.isEmpty) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Text(
//                   'No recent activity',
//                   style: Get.textTheme.bodyMedium?.copyWith(
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ),
//             );
//           }
//
//           return ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: controller.recentActivity.length,
//             separatorBuilder: (_, __) => const Divider(),
//             itemBuilder: (_, index) {
//               final activity = controller.recentActivity[index];
//               return _buildActivityTile(activity);
//             },
//           );
//         }),
//       ],
//     );
//   }
//
//   Widget _buildActivityTile(dynamic activity) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.blue[100],
//             ),
//             child: Icon(
//               Icons.check_circle,
//               color: Colors.blue[600],
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   activity['title'] ?? 'Activity',
//                   style: Get.textTheme.bodyMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Text(
//                   activity['time'] ?? '',
//                   style: Get.textTheme.bodySmall?.copyWith(
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBottomNavBar() {
//     return Obx(() {
//       return BottomNavigationBar(
//         currentIndex: controller.currentNavIndex.value,
//         onTap: controller.changeNavIndex,
//         type: BottomNavigationBarType.fixed,
//         items: [
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.home_outlined),
//             activeIcon: const Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.list_outlined),
//             activeIcon: const Icon(Icons.list),
//             label: 'Issues',
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.add_circle_outline),
//             activeIcon: const Icon(Icons.add_circle),
//             label: 'Report',
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.person_outline),
//             activeIcon: const Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       );
//     });
//   }
// }