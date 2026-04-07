import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analytics_summary.dart';
import 'analytics_ui_shell.dart';

class CitizenAnalyticsHeadlineCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const CitizenAnalyticsHeadlineCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(cs.primary, cs.tertiary, 0.15)!,
            Color.lerp(cs.primary, cs.tertiary, 0.5)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class CitizenAnalyticsStatGrid extends StatelessWidget {
  final AnalyticsSummary summary;
  const CitizenAnalyticsStatGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _CitizenStatCard(label: 'Open', value: '${summary.open}', color: Colors.orange),
        _CitizenStatCard(label: 'Resolved', value: '${summary.resolved}', color: Colors.green),
        _CitizenStatCard(
          label: 'Avg Resolve',
          value: '${summary.averageResolutionHours.toStringAsFixed(1)}h',
          color: Colors.blue,
        ),
        _CitizenStatCard(
          label: 'Avg Duplicates',
          value: summary.averageDuplicateCount.toStringAsFixed(1),
          color: Colors.deepPurple,
        ),
      ],
    );
  }
}

class _CitizenStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CitizenStatCard({
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insights_rounded, size: 15, color: color.withValues(alpha: 0.9)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CitizenStatusDistributionSection extends StatelessWidget {
  final AnalyticsSummary summary;
  const CitizenStatusDistributionSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Reported', summary.reported, Colors.blueGrey),
      ('In Progress', summary.inProgress, Colors.orange),
      ('Reopened', summary.reopened, Colors.deepOrange),
      ('Resolved', summary.resolved, Colors.green),
      ('Rejected', summary.rejected, Colors.red),
    ];

    return AnalyticsSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Distribution',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final ratio = summary.total == 0
                ? 0.0
                : item.$2.toDouble() / summary.total.toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.$1, style: GoogleFonts.inter(fontSize: 12)),
                      Text(
                        '${item.$2}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 9,
                      backgroundColor: item.$3.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(item.$3),
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

class AnalyticsTopSection extends StatelessWidget {
  final String title;
  final String emptyLabel;
  final List<MapEntry<String, int>> items;

  const AnalyticsTopSection({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnalyticsSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              emptyLabel,
              style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 12),
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
                title: Text(
                  item.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                trailing: Text(
                  '${item.value}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              );
            }),
        ],
      ),
    );
  }
}