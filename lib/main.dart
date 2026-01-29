import 'package:civic_connect/src/pages/root/root_page.dart';
import 'package:civic_connect/src/routes/app_pages.dart';
import 'package:civic_connect/src/themes/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CivicConnect',
      themeMode: ThemeMode.light,
      theme: TAppTheme.light(seedColor: Colors.blue),
      darkTheme: TAppTheme.dark(seedColor: Colors.blue),
      home: const RootPage(), // ✅ SINGLE auth entry
      getPages: AppPages.pages,
    );
  }
}
