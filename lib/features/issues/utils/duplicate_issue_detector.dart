import 'package:geolocator/geolocator.dart';
import '../../../core/constants/issue_constants.dart';
import '../../../data/models/issue_model.dart';
import '../models/duplicate_check_result.dart';

class DuplicateIssueDetector {
  static DuplicateCheckResult? findNearestDuplicate({
    required List<IssueModel> candidates,
    required double currentLat,
    required double currentLng,
    required double currentAccuracyMeters,
  }) {
    final radius = IssueConstants.duplicateMinimumRadiusInMeters + currentAccuracyMeters;
    DuplicateCheckResult? nearest;
    double nearestDist = double.infinity;

    for (final issue in candidates) {
      final loc = issue.location;
      if (loc == null) continue;
      final lat = (loc['latitude'] as num?)?.toDouble();
      final lng = (loc['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final dist = Geolocator.distanceBetween(currentLat, currentLng, lat, lng);
      if (dist <= radius && dist < nearestDist) {
        nearestDist = dist;
        nearest = DuplicateCheckResult(issue: issue, distanceMeters: dist);
      }
    }
    return nearest;
  }
}
