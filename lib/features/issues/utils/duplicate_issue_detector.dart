import '../../../core/constants/issue_constants.dart';

class DuplicateIssueDetector {
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
}