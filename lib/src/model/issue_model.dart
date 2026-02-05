class IssueModel {
  final String id;
  final String description;
  final String departmentId;
  final String assignedToDept;
  final String status;
  final String imageUrl;
  final String audioUrl;

  IssueModel({
    required this.id,
    required this.description,
    required this.departmentId,
    required this.assignedToDept,
    required this.status,
    required this.imageUrl,
    required this.audioUrl,
  });

  factory IssueModel.fromFirestore(String id, Map<String, dynamic> data) {
    return IssueModel(
      id: id,
      description: data['description'],
      departmentId: data['departmentId'],
      assignedToDept: data['assignedToDept'],
      status: data['status'],
      imageUrl: data['imageUrl'],
      audioUrl: data['audioUrl'],
    );
  }
}
