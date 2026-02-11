import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final double borderRadius;
  final Border? border;
  final BoxShadow? shadow;
  final VoidCallback? onTap;

  const SectionCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderRadius = 12,
    this.border,
    this.shadow,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ?? Border.all(color: AppColors.divider),
          boxShadow: shadow != null ? [shadow!] : null,
        ),
        child: child,
      ),
    );
  }
}