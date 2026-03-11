import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../models/notification_item.dart';

class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.isRead ? null : AppColors.primary.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusIcon(status: item.status),
            const SizedBox(width: 12),
            Expanded(child: _NotificationBody(item: item)),
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _bgColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(_icon, color: _bgColor, size: 22),
    );
  }

  IconData get _icon => switch (status) {
    'in-progress' => Icons.construction_rounded,
    'resolved'    => Icons.check_circle_rounded,
    'rejected'    => Icons.cancel_rounded,
    _             => Icons.info_rounded,
  };

  Color get _bgColor => switch (status) {
    'in-progress' => AppColors.statusInProgress,
    'resolved'    => AppColors.statusResolved,
    'rejected'    => AppColors.statusRejected,
    _             => AppColors.statusAssigned,
  };
}

class _NotificationBody extends StatelessWidget {
  final NotificationItem item;
  const _NotificationBody({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            children: [
              TextSpan(
                text: item.categoryId.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: ' issue status changed to '),
              TextSpan(
                text: _statusLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
            ],
          ),
        ),
        if (item.message.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            item.message,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          _formatTime(item.timestamp),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String get _statusLabel => switch (item.status) {
    'in-progress' => 'In Progress',
    'resolved'    => 'Resolved',
    'rejected'    => 'Rejected',
    _             => item.status,
  };

  Color get _statusColor => switch (item.status) {
    'in-progress' => AppColors.statusInProgress,
    'resolved'    => AppColors.statusResolved,
    'rejected'    => AppColors.statusRejected,
    _             => AppColors.statusAssigned,
  };

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)    return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}