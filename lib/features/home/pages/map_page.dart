import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(Icons.map_rounded, size: 56, color: cs.primary),
          ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
          const SizedBox(height: 20),
          Text('Map View', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text('Coming Soon', style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant))
              .animate().fadeIn(delay: 150.ms),
        ],
      ),
    );
  }
}
