import 'package:cloud_firestore/cloud_firestore.dart';

class IssueCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final int order;
  final bool active;
  final String assignedDepartment;

  IssueCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.order,
    required this.active,
    required this.assignedDepartment,
  });

  factory IssueCategory.fromFirestore(String id, Map<String, dynamic> data) {
    return IssueCategory(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      color: data['color'] ?? '',
      order: data['order'] ?? 0,
      active: data['active'] ?? true,
      assignedDepartment: data['assignedDepartment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'order': order,
      'active': active,
      'assignedDepartment': assignedDepartment,
    };
  }
}