import 'package:cloud_firestore/cloud_firestore.dart';

class CitizenFeedbackModel {
  final String issueId;
  final String citizenEmail;
  final int overallRating;       // 1–5 stars
  final int workQualityScore;    // 1–5 stars
  final int timelinessScore;     // 1–5 stars
  final bool issueActuallyFixed; // Ground truth from citizen
  final String comments;
  final DateTime submittedAt;

  const CitizenFeedbackModel({
    required this.issueId,
    required this.citizenEmail,
    required this.overallRating,
    required this.workQualityScore,
    required this.timelinessScore,
    required this.issueActuallyFixed,
    required this.comments,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() => {
    'issueId': issueId,
    'citizenEmail': citizenEmail,
    'overallRating': overallRating,
    'workQualityScore': workQualityScore,
    'timelinessScore': timelinessScore,
    'issueActuallyFixed': issueActuallyFixed,
    'comments': comments,
    'submittedAt': Timestamp.fromDate(submittedAt),
  };

  factory CitizenFeedbackModel.fromMap(Map<String, dynamic> map) =>
      CitizenFeedbackModel(
        issueId: map['issueId'] ?? '',
        citizenEmail: map['citizenEmail'] ?? '',
        overallRating: (map['overallRating'] as num?)?.toInt() ?? 1,
        workQualityScore: (map['workQualityScore'] as num?)?.toInt() ?? 1,
        timelinessScore: (map['timelinessScore'] as num?)?.toInt() ?? 1,
        issueActuallyFixed: map['issueActuallyFixed'] ?? false,
        comments: map['comments'] ?? '',
        submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      );
}