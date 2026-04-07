import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analytics_summary.dart';
import 'analytics_ui_shell.dart';

class AdminAnalyticsHeader extends StatelessWidget {
  final String adminName;
  final String departmentId;
  final AnalyticsSummary summary;

  const AdminAnalyticsHeader({
    super.key,
    required this.adminName,
    required this.departmentId,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(cs.primary, cs.tertiary, 0.2)!,
            Color.lerp(cs.primary, cs.tertiary, 0.55)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $adminName',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            departmentId.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.open} open issues and ${summary.unresolvedHighPriority} high-priority unresolved cases.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminAnalyticsStatGrid extends StatelessWidget {
  final AnalyticsSummary summary;
  const AdminAnalyticsStatGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _AdminStatPill(label: 'Total', value: '${summary.total}', color: Colors.blueGrey),
        _AdminStatPill(label: 'Open', value: '${summary.open}', color: Colors.orange),
        _AdminStatPill(label: 'Resolved', value: '${summary.resolved}', color: Colors.green),
        _AdminStatPill(
          label: 'High Priority',
          value: '${summary.unresolvedHighPriority}',
          color: Colors.red,
        ),
        _AdminStatPill(
          label: 'Avg Resolve',
          value: '${summary.averageResolutionHours.toStringAsFixed(1)}h',
          color: Colors.indigo,
        ),
        _AdminStatPill(
          label: 'Citizen Rating',
          value: summary.citizenRatingAverage == 0
              ? 'NA'
              : summary.citizenRatingAverage.toStringAsFixed(1),
          color: Colors.teal,
        ),
      ],
    );
  }
}

class _AdminStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AdminStatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 42) / 2;
    return SizedBox(
      width: width,
      child: AnalyticsSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminStatusDistributionSection extends StatelessWidget {
  final AnalyticsSummary summary;
  const AdminStatusDistributionSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Reported', summary.reported, Colors.blueGrey),
      ('In Progress', summary.inProgress, Colors.orange),
      ('Resolved', summary.resolved, Colors.green),
      ('Rejected', summary.rejected, Colors.red),
      ('Reopened', summary.reopened, Colors.deepOrange),
    ];

    return AnalyticsSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department Status Mix',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ...rows.map((row) {
            final ratio = summary.total == 0
                ? 0.0
                : row.$2.toDouble() / summary.total.toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(row.$1, style: GoogleFonts.inter(fontSize: 12)),
                      Text(
                        '${row.$2}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 9,
                      backgroundColor: row.$3.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(row.$3),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}