import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../sign_in/sign_in_page.dart';
import '../home/admin/home_admin.dart';
import '../home/citizen/home_citizen.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Waiting for Firebase
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in
        if (!authSnapshot.hasData) {
          return SignInPage();
        }

        // Logged in → fetch role
        final uid = authSnapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future:
          FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              FirebaseAuth.instance.signOut();
              return SignInPage();
            }

            final role = userSnapshot.data!.get('role');

            if (role == 'admin') {
              return const HomeAdmin();
            } else {
              return const HomeCitizen();
            }
          },
        );
      },
    );
  }
}

