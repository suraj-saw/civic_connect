import '../../../data/models/issue_model.dart';

class DuplicateCheckResult {
  final IssueModel issue;
  final double distanceMeters;

  const DuplicateCheckResult({required this.issue, required this.distanceMeters});
}
