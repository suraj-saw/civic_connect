import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class IssueStatusChip extends StatelessWidget {
  final String status;

  const IssueStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusData(status);

    return Chip(
      avatar: Icon(statusData.icon, size: 18, color: Colors.white),
      label: Text(
        status.toUpperCase(),
        style: AppTextStyles.chipLabel,
      ),
      backgroundColor: statusData.color,
    );
  }

  _StatusData _getStatusData(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return _StatusData(AppColors.statusReported, Icons.report);
      case 'assigned':
        return _StatusData(AppColors.statusAssigned, Icons.assignment);
      case 'in-progress':
        return _StatusData(AppColors.statusInProgress, Icons.hourglass_bottom);
      case 'resolved':
        return _StatusData(AppColors.statusResolved, Icons.check_circle);
      case 'rejected':
        return _StatusData(AppColors.statusRejected, Icons.cancel);
      default:
        return _StatusData(Colors.grey, Icons.help);
    }
  }
}

class _StatusData {
  final Color color;
  final IconData icon;

  _StatusData(this.color, this.icon);
}