import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = ThemeController.to;
    return Obx(() => IconButton(
      tooltip: ctrl.isDark.value ? 'Switch to Light' : 'Switch to Dark',
      onPressed: ctrl.toggle,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          ctrl.isDark.value ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(ctrl.isDark.value),
        ),
      ),
    ));
  }
}
