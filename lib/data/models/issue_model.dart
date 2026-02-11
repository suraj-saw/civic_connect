import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineEntry {
  final String status;
  final String message;
  final String updatedBy;
  final String updatedByEmail;
  final DateTime timestamp;

  TimelineEntry({
    required this.status,
    required this.message,
    required this.updatedBy,
    required this.updatedByEmail,
    required this.timestamp,
  });

  factory TimelineEntry.fromMap(Map<String, dynamic> map) {
    return TimelineEntry(
      status: map['status'] ?? '',
      message: map['message'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      updatedByEmail: map['updatedByEmail'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'message': message,
      'updatedBy': updatedBy,
      'updatedByEmail': updatedByEmail,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class IssueModel {
  final String? id;
  final String categoryId;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final Map<String, double>? location;
  final String reporterEmail;
  final String assignedToDept;
  final String status;
  final DateTime createdAt;
  final List<TimelineEntry> timeline;

  IssueModel({
    this.id,
    required this.categoryId,
    required this.description,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.location,
    required this.reporterEmail,
    required this.assignedToDept,
    this.status = 'reported',
    required this.createdAt,
    List<TimelineEntry>? timeline,
  }) : timeline = timeline ?? [];

  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<TimelineEntry> timelineList = [];
    if (data['timeline'] != null) {
      timelineList = (data['timeline'] as List)
          .map((e) => TimelineEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return IssueModel(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      audioUrl: data['audioUrl'],
      location: data['location'] != null
          ? Map<String, double>.from(data['location'])
          : null,
      reporterEmail: data['reporterEmail'] ?? '',
      assignedToDept: data['assignedToDept'] ?? '',
      status: data['status'] ?? 'reported',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      timeline: timelineList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'location': location,
      'reporterEmail': reporterEmail,
      'assignedToDept': assignedToDept,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'timeline': timeline.map((e) => e.toMap()).toList(),
    };
  }
}