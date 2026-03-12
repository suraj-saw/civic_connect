import 'package:civic_connect/features/root/pages/root_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/controllers/theme_controller.dart';
import 'core/routes/app_pages.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  Get.put(ThemeController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;

    return Obx(() => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CivicConnect',
      themeMode: themeController.isDark.value ? ThemeMode.dark : ThemeMode.light,
      theme: TAppTheme.light(seedColor: Colors.blue),
      darkTheme: TAppTheme.dark(seedColor: Colors.blue),
      home: const RootPage(),
      getPages: AppPages.pages,
    ));
  }
}