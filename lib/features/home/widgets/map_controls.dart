import 'package:flutter/material.dart';

/// Circular button for map controls
class MapCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const MapCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: const CircleBorder(),
      elevation: 4,
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

  const MapControlStack({required this.topButton, required this.bottomButton});

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

  const MapTypeTile({
    required this.title,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Container(
              width: 86,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors:
                      selected
                          ? [const Color(0xFF81D4FA), const Color(0xFFB2DFDB)]
                          : [const Color(0xFFCFD8DC), const Color(0xFFECEFF1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color:
                      selected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.35),
                  width: selected ? 2.2 : 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

  const MapTypeGrid({
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
  final VoidCallback onTap;

  const MapDetailTile({
    required this.title,
    required this.selected,
    required this.icon,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 104,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color:
                    selected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color:
                      selected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.35),
                  width: selected ? 2.2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: selected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

  const MapDetailsGrid({
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

/// Placeholder shown when Mapbox token is missing
class MissingTokenView extends StatelessWidget {
  const MissingTokenView();

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
            color: cs.errorContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.error.withValues(alpha: 0.2)),
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
                ).textTheme.titleMedium?.copyWith(color: cs.error),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your Mapbox public token to the .env file in the project root.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
