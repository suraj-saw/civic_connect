import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  final _box = GetStorage();
  static const _key = 'isDarkMode';

  final isDark = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDark.value = _box.read<bool>(_key) ?? false;
    _applyTheme();
  }

  void toggle() {
    isDark.value = !isDark.value;
    _box.write(_key, isDark.value);
    _applyTheme();
  }

  void _applyTheme() {
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
  }
}