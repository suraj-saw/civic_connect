import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Utility functions for map status-related styling and icons
class MapStatusUtils {
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return AppColors.statusReported;
      case 'assigned':
        return AppColors.statusAssigned;
      case 'in_progress':
      case 'inprogress':
        return AppColors.statusInProgress;
      case 'resolved':
        return AppColors.statusResolved;
      case 'rejected':
        return AppColors.statusRejected;
      default:
        return AppColors.primary;
    }
  }

  static IconData getStatusIconData(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return Icons.info_rounded;
      case 'assigned':
        return Icons.person_rounded;
      case 'in_progress':
      case 'inprogress':
        return Icons.construction_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  static String getStatusBadgeText(String status) {
    return status.toUpperCase();
  }
}
