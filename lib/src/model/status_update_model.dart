import 'package:cloud_firestore/cloud_firestore.dart';

class StatusUpdate {
  final String id;
  final String status;
  final String message;
  final String updatedBy;
  final String updatedByEmail;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  StatusUpdate({
    required this.id,
    required this.status,
    required this.message,
    required this.updatedBy,
    required this.updatedByEmail,
    required this.updatedAt,
    this.metadata,
  });

  factory StatusUpdate.fromFirestore(String id, Map<String, dynamic> data) {
    return StatusUpdate(
      id: id,
      status: data['status'] ?? '',
      message: data['message'] ?? '',
      updatedBy: data['updatedBy'] ?? '',
      updatedByEmail: data['updatedByEmail'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'message': message,
      'updatedBy': updatedBy,
      'updatedByEmail': updatedByEmail,
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': metadata,
    };
  }
}