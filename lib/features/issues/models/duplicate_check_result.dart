import '../../../data/models/issue_model.dart';

/// Carries the result of a duplicate-issue look-up: the nearest matching
/// [IssueModel] and how far (in metres) it is from the citizen's location.
class DuplicateCheckResult {
  final IssueModel issue;
  final double distanceInMeters;

  const DuplicateCheckResult({
    required this.issue,
    required this.distanceInMeters,
  });
}