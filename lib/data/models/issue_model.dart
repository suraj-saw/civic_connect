import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineEntry {
  final String status;
  final String message;
  final String updatedBy;
  final String updatedByEmail;
  final DateTime timestamp;

  TimelineEntry({required this.status, required this.message, required this.updatedBy, required this.updatedByEmail, required this.timestamp});

  factory TimelineEntry.fromMap(Map<String, dynamic> map) => TimelineEntry(
    status: map['status'] ?? '', message: map['message'] ?? '',
    updatedBy: map['updatedBy'] ?? '', updatedByEmail: map['updatedByEmail'] ?? '',
    timestamp: (map['timestamp'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {'status': status, 'message': message, 'updatedBy': updatedBy, 'updatedByEmail': updatedByEmail, 'timestamp': Timestamp.fromDate(timestamp)};
}

class IssueModel {
  final String? id;
  final String categoryId;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final Map<String, dynamic>? location;
  final String reporterEmail;
  final String assignedToDept;
  final String status;
  final DateTime createdAt;
  final List<TimelineEntry> timeline;
  final int duplicateReportCount;
  final List<String> duplicateReporters;

  IssueModel({this.id, required this.categoryId, required this.description,
    this.imageUrl, this.videoUrl, this.audioUrl, this.location,
    required this.reporterEmail, required this.assignedToDept,
    this.status = 'reported', required this.createdAt,
    List<TimelineEntry>? timeline, this.duplicateReportCount = 1, List<String>? duplicateReporters})
      : timeline = timeline ?? [], duplicateReporters = duplicateReporters ?? [];

  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IssueModel(
      id: doc.id, categoryId: data['categoryId'] ?? '', description: data['description'] ?? '',
      imageUrl: data['imageUrl'], videoUrl: data['videoUrl'], audioUrl: data['audioUrl'],
      location: data['location'] != null ? Map<String, dynamic>.from(data['location']) : null,
      reporterEmail: data['reporterEmail'] ?? '', assignedToDept: data['assignedToDept'] ?? '',
      status: data['status'] ?? 'reported',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      timeline: (data['timeline'] as List?)?.map((e) => TimelineEntry.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      duplicateReportCount: (data['duplicateReportCount'] as int?) ?? 1,
      duplicateReporters: data['duplicateReporters'] != null ? List<String>.from(data['duplicateReporters']) : [],
    );
  }
}
