import 'package:flutter/material.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cards/info_card.dart';

class IssueInfoSection extends StatelessWidget {
  final String title;
  final List<InfoRow> rows;

  const IssueInfoSection({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: AppTextStyles.sectionTitle),
        ),
        InfoCard(rows: rows),
      ],
    );
  }
}

class InfoRow {
  final String label;
  final String value;

  const InfoRow(this.label, this.value);
}