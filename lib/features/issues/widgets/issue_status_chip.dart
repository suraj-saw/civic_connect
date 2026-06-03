import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IssueStatusChip extends StatelessWidget {
  final String status;
  const IssueStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    final icon  = _icon(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Color _color(String s) {
    switch (s.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'in-progress': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'reopened': return Colors.deepOrange;
      default: return Colors.grey;
    }
  }

  IconData _icon(String s) {
    switch (s.toLowerCase()) {
      case 'resolved': return Icons.check_circle_rounded;
      case 'in-progress': return Icons.hourglass_bottom_rounded;
      case 'assigned': return Icons.assignment_rounded;
      case 'rejected': return Icons.cancel_rounded;
      case 'reopened': return Icons.refresh_rounded;
      default: return Icons.report_rounded;
    }
  }
}

