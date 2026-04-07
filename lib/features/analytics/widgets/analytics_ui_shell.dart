import 'package:flutter/material.dart';

class AnalyticsBackground extends StatelessWidget {
  final Widget child;
  const AnalyticsBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(cs.primaryContainer, cs.surface, isDark ? 0.6 : 0.35)!,
            cs.surface,
            cs.surface,
          ],
          stops: const [0, 0.24, 1],
        ),
      ),
      child: child,
    );
  }
}

class AnalyticsSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AnalyticsSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.primary.withValues(alpha: isDark ? 0.08 : 0.02),
          cs.surface,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outline.withValues(alpha: isDark ? 0.3 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: isDark ? 18 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}