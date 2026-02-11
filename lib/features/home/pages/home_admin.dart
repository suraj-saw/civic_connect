import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_admin_controller.dart';

class HomeAdminPage extends StatelessWidget {
  const HomeAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeAdminController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome Admin",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add admin functionality here
              },
              child: const Text("View All Issues"),
            ),
          ],
        ),
      ),
    );
  }
}