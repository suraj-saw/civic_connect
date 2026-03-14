class CitizenFeedbackModel {
  final String issueId;
  final String citizenEmail;
  final int overallRating;
  final int workQualityScore;
  final int timelinessScore;
  final bool issueActuallyFixed;
  final String comments;
  final DateTime submittedAt;

  CitizenFeedbackModel({required this.issueId, required this.citizenEmail, required this.overallRating,
    required this.workQualityScore, required this.timelinessScore, required this.issueActuallyFixed,
    required this.comments, required this.submittedAt});

  factory CitizenFeedbackModel.fromMap(Map<String, dynamic> map) => CitizenFeedbackModel(
    issueId: map['issueId'] ?? '', citizenEmail: map['citizenEmail'] ?? '',
    overallRating: map['overallRating'] ?? 3, workQualityScore: map['workQualityScore'] ?? 3,
    timelinessScore: map['timelinessScore'] ?? 3, issueActuallyFixed: map['issueActuallyFixed'] ?? true,
    comments: map['comments'] ?? '', submittedAt: (map['submittedAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'issueId': issueId, 'citizenEmail': citizenEmail,
    'overallRating': overallRating, 'workQualityScore': workQualityScore,
    'timelinessScore': timelinessScore, 'issueActuallyFixed': issueActuallyFixed,
    'comments': comments, 'submittedAt': submittedAt,
  };
}
