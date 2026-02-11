import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../issues/controllers/issue_category_controller.dart';
import '../../issues/pages/issue_detail_admin_page.dart';
import '../controllers/home_admin_controller.dart';
import '../widgets/admin/admin_drawer.dart';

class HomeAdminPage extends StatelessWidget {
  const HomeAdminPage({super.key});


  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeAdminController());
    final categoryController = Get.put(IssueCategoryController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text("Admin • ${controller.adminDept.value.toUpperCase()}"),
          centerTitle: true,
        ),
        drawer: const AdminDrawer(),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('issues')
              .where('assignedToDept',
              isEqualTo: controller.adminDept.value)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {

            if (snapshot.hasError) {
              // 🔥 Ignore permission denied during logout
              if (snapshot.error
                  .toString()
                  .contains('permission-denied')) {
                return const SizedBox();
              }

              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No issues assigned to your department",
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data =
                doc.data() as Map<String, dynamic>;

                return ListTile(
                  title: Text(data['categoryId'] ?? ''),
                );
              },
            );
          },
        ),
      );
    });
  }
}

