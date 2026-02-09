// class IssueModel {
//   final String id;
//   final String description;
//   final String departmentId;
//   final String assignedToDept;
//   final String status;
//   final String imageUrl;
//   final String audioUrl;
//
//   IssueModel({
//     required this.id,
//     required this.description,
//     required this.departmentId,
//     required this.assignedToDept,
//     required this.status,
//     required this.imageUrl,
//     required this.audioUrl,
//   });
//
//   factory IssueModel.fromFirestore(String id, Map<String, dynamic> data) {
//     return IssueModel(
//       id: id,
//       description: data['description'],
//       departmentId: data['departmentId'],
//       assignedToDept: data['assignedToDept'],
//       status: data['status'],
//       imageUrl: data['imageUrl'],
//       audioUrl: data['audioUrl'],
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';

class IssueTimeline {
  final String status;
  final String message;
  final String updatedBy;
  final DateTime timestamp;

  IssueTimeline({
    required this.status,
    required this.message,
    required this.updatedBy,
    required this.timestamp,
  });

  factory IssueTimeline.fromMap(Map<String, dynamic> map) {
    return IssueTimeline(
      status: map['status'],
      message: map['message'],
      updatedBy: map['updatedBy'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class IssueModel {
  final String id;
  final String description;
  final String categoryId;
  final String status;
  final String reportedBy;

  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;

  final List<IssueTimeline> timeline;

  IssueModel({
    required this.id,
    required this.description,
    required this.categoryId,
    required this.status,
    required this.reportedBy,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    required this.timeline,
  });

  factory IssueModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return IssueModel(
      id: doc.id,
      description: data['description'],
      categoryId: data['categoryId'],
      status: data['status'],
      reportedBy: data['reportedBy'],
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      audioUrl: data['audioUrl'],
      timeline: (data['timeline'] as List<dynamic>? ?? [])
          .map((e) => IssueTimeline.fromMap(e))
          .toList(),
    );
  }
}

