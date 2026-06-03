import 'package:flutter/material.dart';

/// Circular button for map controls
class MapCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const MapCircleButton({super.key, 
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Color.alphaBlend(
        cs.primary.withValues(alpha: isDark ? 0.12 : 0.04),
        cs.surface,
      ),
      shape: const CircleBorder(),
      elevation: isDark ? 2.5 : 4,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.34 : 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Stack layout for map control buttons
class MapControlStack extends StatelessWidget {
  final Widget topButton;
  final Widget bottomButton;

  const MapControlStack({super.key, required this.topButton, required this.bottomButton});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [topButton, const SizedBox(height: 10), bottomButton],
    );
  }
}

/// Individual map type tile
class MapTypeTile extends StatelessWidget {
  final String title;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const MapTypeTile({super.key, 
    required this.title,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = _MapTypePreview(title: title, selected: selected, colorScheme: colorScheme);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 98,
        child: Column(
          children: [
            preview,
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid layout for map type options
class MapTypeGrid extends StatelessWidget {
  final Map<String, String> options;
  final String selectedStyle;
  final ValueChanged<String> onSelect;

  const MapTypeGrid({super.key, 
    required this.options,
    required this.selectedStyle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();
    return Row(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          Expanded(
            child: MapTypeTile(
              title: entries[index].key,
              selected: selectedStyle == entries[index].value,
              colorScheme: Theme.of(context).colorScheme,
              onTap: () => onSelect(entries[index].value),
            ),
          ),
          if (index < entries.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

/// Individual map detail tile (traffic, public transport, etc.)
class MapDetailTile extends StatelessWidget {
  final String title;
  final bool selected;
  final IconData icon;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;
  final bool enabled;

  const MapDetailTile({super.key, 
    required this.title,
    required this.selected,
    required this.icon,
    required this.colorScheme,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        !enabled
            ? colorScheme.onSurface.withValues(alpha: 0.48)
            : (selected ? colorScheme.primary : colorScheme.onSurface);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color:
                    !enabled
                        ? colorScheme.surfaceContainerHighest
                        : selected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color:
                      !enabled
                          ? colorScheme.outline.withValues(alpha: 0.2)
                          : selected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.35),
                  width: selected ? 2.2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid layout for map detail options
class MapDetailsGrid extends StatelessWidget {
  final bool showPublicTransport;
  final bool showTraffic;
  final VoidCallback onTogglePublicTransport;
  final VoidCallback onToggleTraffic;

  const MapDetailsGrid({super.key, 
    required this.showPublicTransport,
    required this.showTraffic,
    required this.onTogglePublicTransport,
    required this.onToggleTraffic,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        MapDetailTile(
          title: 'Public\ntransport',
          selected: showPublicTransport,
          icon: Icons.directions_transit_rounded,
          colorScheme: cs,
          onTap: onTogglePublicTransport,
        ),
        MapDetailTile(
          title: 'Traffic',
          selected: showTraffic,
          icon: Icons.traffic_rounded,
          colorScheme: cs,
          onTap: onToggleTraffic,
        ),
      ],
    );
  }
}

class _MapTypePreview extends StatelessWidget {
  final String title;
  final bool selected;
  final ColorScheme colorScheme;

  const _MapTypePreview({
    required this.title,
    required this.selected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    late final Color baseA;
    late final Color baseB;
    late final Color landTint;
    late final Color roadMain;
    late final Color roadMinor;
    late final Color water;

    if (title == 'Satellite') {
      baseA = isDark ? const Color(0xFF4B5A52) : const Color(0xFF7A8A80);
      baseB = isDark ? const Color(0xFF313A35) : const Color(0xFF5B665E);
      landTint = isDark ? const Color(0xFF778678) : const Color(0xFF99A78E);
      roadMain = isDark ? const Color(0xFFD9D9D1) : const Color(0xFFF1F1E6);
      roadMinor = isDark ? const Color(0xFFB7B7AF) : const Color(0xFFDBDBCF);
      water = isDark ? const Color(0xFF3D6E7B) : const Color(0xFF6EB3C2);
    } else if (title == 'Terrain') {
      baseA = isDark ? const Color(0xFF4B6152) : const Color(0xFF8AA782);
      baseB = isDark ? const Color(0xFF2D4035) : const Color(0xFF67806A);
      landTint = isDark ? const Color(0xFF7B8E71) : const Color(0xFFAEC39A);
      roadMain = isDark ? const Color(0xFFE0E2D7) : const Color(0xFFF4F2E8);
      roadMinor = isDark ? const Color(0xFFC4C9BA) : const Color(0xFFE1E4D7);
      water = isDark ? const Color(0xFF3B6C84) : const Color(0xFF7CC4DC);
    } else {
      baseA = isDark ? const Color(0xFF2E5B66) : const Color(0xFF68B8CD);
      baseB = isDark ? const Color(0xFF356678) : const Color(0xFF8FD1E1);
      landTint = isDark ? const Color(0xFF6AA07E) : const Color(0xFFBCE6C8);
      roadMain = isDark ? const Color(0xFFE9E6D8) : const Color(0xFFFDF9EB);
      roadMinor = isDark ? const Color(0xFFD0CBB7) : const Color(0xFFE8E2CF);
      water = isDark ? const Color(0xFF4D8EA8) : const Color(0xFF9ADDF5);
    }

    return Container(
      width: 86,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [baseA, baseB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color:
              selected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: isDark ? 0.5 : 0.32),
          width: selected ? 2.2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Positioned(
              left: -10,
              right: -10,
              top: 36,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: water.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            Positioned(
              left: -6,
              top: -3,
              child: Transform.rotate(
                angle: -0.24,
                child: Container(
                  width: 58,
                  height: 26,
                  decoration: BoxDecoration(
                    color: landTint.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -10,
              bottom: 16,
              child: Transform.rotate(
                angle: 0.28,
                child: Container(
                  width: 46,
                  height: 20,
                  decoration: BoxDecoration(
                    color: landTint.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -8,
              right: -6,
              top: 15,
              child: Transform.rotate(
                angle: -0.12,
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: roadMain,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              top: 27,
              child: Transform.rotate(
                angle: 0.34,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: roadMinor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 34,
              top: 20,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.88 : 0.96),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.85),
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown when Mapbox token is missing
class MissingTokenView extends StatelessWidget {
  const MissingTokenView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.error.withValues(alpha: 0.28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_rounded, color: cs.error, size: 32),
              const SizedBox(height: 12),
              Text(
                'Configuration Missing',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your Mapbox public token to the .env file in the project root.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
