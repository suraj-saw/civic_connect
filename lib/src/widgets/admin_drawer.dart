import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth/sign_in_controller.dart';
import '../controllers/bottom_navigation/home_citizen_controller.dart';

class AdminDrawer extends StatelessWidget {
  AdminDrawer({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;

    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(data['name'] ?? 'Admin'),
                accountEmail: Text(data['email'] ?? ''),
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.person, size: 40),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Profile"),
                onTap: () {
                  Navigator.pop(context); // close drawer
                  Get.toNamed('/profile');
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout"),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();

                  if (Get.isRegistered<HomeCitizenController>()) {
                    Get.find<HomeCitizenController>().resetToDashboard();
                  }

                  if (Get.isRegistered<SignInController>()) {
                    Get.find<SignInController>().clearFields();
                  }
                },


              ),
            ],
          );
        },
      ),
    );
  }
}
