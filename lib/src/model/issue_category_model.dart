class IssueCategory {
  final String id;
  final String name;

  IssueCategory({
    required this.id,
    required this.name,
  });

  factory IssueCategory.fromFirestore(String id, Map<String, dynamic> data) {
    return IssueCategory(
      id: id,
      name: data['name'] ?? '',
    );
  }
}
