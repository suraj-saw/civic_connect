import 'package:geolocator/geolocator.dart';

import '../../../core/constants/issue_constants.dart';
import '../../../data/models/issue_model.dart';
import '../models/duplicate_check_result.dart';

class DuplicateIssueDetector {
  /// Clamps a raw GPS accuracy value into the allowed [min, max] range.
  static double parseAccuracyInMeters(dynamic accuracyValue) {
    final parsed = (accuracyValue as num?)?.toDouble();
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed <= 0) {
      return IssueConstants.duplicateMinimumRadiusInMeters;
    }
    return parsed.clamp(
      IssueConstants.duplicateMinimumRadiusInMeters,
      IssueConstants.duplicateMaximumRadiusInMeters,
    );
  }

  /// Returns the distance (metres) within which two reports are considered
  /// the same physical issue, given each report's GPS accuracy.
  static double calculateMatchThreshold({
    required double currentAccuracy,
    required double existingAccuracy,
  }) {
    return (currentAccuracy +
            existingAccuracy +
            IssueConstants.duplicateUncertaintyBufferInMeters)
        .clamp(
      IssueConstants.duplicateMinimumRadiusInMeters,
      IssueConstants.duplicateMaximumRadiusInMeters,
    );
  }

  /// Scans [candidates] (same category, already filtered by Firestore) for the
  /// nearest issue whose GPS location falls within [calculateMatchThreshold].
  ///
  /// Returns `null` when no match is found (i.e. this is a genuinely new issue).
  static DuplicateCheckResult? findNearestDuplicate({
    required List<IssueModel> candidates,
    required double currentLat,
    required double currentLng,
    required double currentAccuracyMeters,
  }) {
    DuplicateCheckResult? nearest;

    for (final issue in candidates) {
      final location = issue.location;
      if (location == null) continue;

      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final existingAccuracy = parseAccuracyInMeters(location['accuracy']);
      final threshold = calculateMatchThreshold(
        currentAccuracy: parseAccuracyInMeters(currentAccuracyMeters),
        existingAccuracy: existingAccuracy,
      );

      final distance =
          Geolocator.distanceBetween(currentLat, currentLng, lat, lng);

      if (distance <= threshold) {
        if (nearest == null || distance < nearest.distanceInMeters) {
          nearest = DuplicateCheckResult(
            issue: issue,
            distanceInMeters: distance,
          );
        }
      }
    }

    return nearest;
  }
}