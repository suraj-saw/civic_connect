import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../auth/controllers/sign_in_controller.dart';
import '../../home/controllers/home_citizen_controller.dart';
import '../../issues/controllers/my_issues_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../notifications/controllers/notification_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _handleLogout() async {
    try {
      if (Get.isRegistered<MyIssuesController>()) {
        Get.delete<MyIssuesController>(force: true);
      }
      if (Get.isRegistered<NotificationController>()) {
        Get.delete<NotificationController>(force: true);
      }
      if (Get.isRegistered<HomeCitizenController>()) {
        Get.find<HomeCitizenController>().resetToDashboard();
        Get.delete<HomeCitizenController>(force: true);
      }
      if (Get.isRegistered<SignInController>()) {
        Get.find<SignInController>().clearFields();
      }

      await FirebaseAuth.instance.signOut();
      Get.offAllNamed(AppRoutes.signIn);
    } catch (e) {
      print('LOGOUT ERROR: $e');
      Get.snackbar('Error', 'Failed to logout. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Could not load profile"));
          }

          final data = snapshot.data!.data()!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      (data['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _profileTile("Name", data['name']),
                _profileTile("Email", data['email']),
                _profileTile("Phone", data['phone']),
                _profileTile(
                  "Phone Verified",
                  data['phoneVerified'] == true ? "Yes" : "No",
                ),
                _profileTile(
                  "Role",
                  (data['role'] as String).toUpperCase(),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.red,
                    ),
                    onPressed: _handleLogout,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileTile(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? '-',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}