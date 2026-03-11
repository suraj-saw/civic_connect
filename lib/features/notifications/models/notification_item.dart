// lib/features/notifications/models/notification_item.dart

class NotificationItem {
  final String issueId;
  final String categoryId;
  final String status;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const NotificationItem({
    required this.issueId,
    required this.categoryId,
    required this.status,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      issueId: issueId,
      categoryId: categoryId,
      status: status,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}