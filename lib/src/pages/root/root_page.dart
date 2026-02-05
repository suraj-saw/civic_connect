import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/report_issue/issue_category_controller.dart';
import '../sign_in/sign_in_page.dart';
import '../home/admin/home_admin.dart';
import '../home/citizen/home_citizen.dart';

// class RootPage extends StatelessWidget {
//   const RootPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, authSnapshot) {
//         // Waiting for Firebase auth
//         if (authSnapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         // ❌ Not logged in
//         if (!authSnapshot.hasData) {
//           return SignInPage();
//         }
//
//         // ✅ Logged in → fetch user role
//         final uid = authSnapshot.data!.uid;
//
//         return FutureBuilder<DocumentSnapshot>(
//           future: FirebaseFirestore.instance
//               .collection('users')
//               .doc(uid)
//               .get(),
//           builder: (context, userSnapshot) {
//             if (userSnapshot.connectionState ==
//                 ConnectionState.waiting) {
//               return const Scaffold(
//                 body: Center(child: CircularProgressIndicator()),
//               );
//             }
//
//             // ❌ User document missing
//             if (!userSnapshot.hasData ||
//                 !userSnapshot.data!.exists) {
//               // DO NOT sign out here
//               return SignInPage();
//             }
//
//             final role = userSnapshot.data!.get('role');
//
//             if (role == 'admin') {
//               return HomeAdmin();
//             } else {
//               return const HomeCitizen();
//             }
//           },
//         );
//       },
//     );
//   }
// }

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {

    // 🔥 REGISTER CATEGORY CONTROLLER GLOBALLY (ONCE)
    if (!Get.isRegistered<IssueCategoryController>()) {
      Get.put(IssueCategoryController(), permanent: true);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnapshot.hasData) {
          return SignInPage();
        }

        final uid = authSnapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = userSnapshot.data!.get('role');

            if (role == 'admin') {
              return HomeAdmin();
            } else {
              return const HomeCitizen();
            }
          },
        );
      },
    );
  }
}
