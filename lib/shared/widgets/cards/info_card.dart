import 'package:flutter/material.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/issues/widgets/issue_info_section.dart';

class InfoCard extends StatelessWidget {
  final List<InfoRow> rows;

  const InfoCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows.map((row) => _buildInfoRow(row)).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoRow(InfoRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(row.label, style: AppTextStyles.cardLabel),
          ),
          Expanded(
            child: Text(row.value, style: AppTextStyles.cardValue),
          ),
        ],
      ),
    );
  }
}