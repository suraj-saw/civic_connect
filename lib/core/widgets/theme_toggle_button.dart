import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.to;
    return Obx(() => IconButton(
      tooltip: controller.isDark.value ? 'Switch to Light' : 'Switch to Dark',
      icon: Icon(
        controller.isDark.value ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      ),
      onPressed: controller.toggle,
    ));
  }
}