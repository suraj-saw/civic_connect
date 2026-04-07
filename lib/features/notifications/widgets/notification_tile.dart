import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_colors.dart';
import '../models/notification_item.dart';

class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const NotificationTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUnread = !item.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(minHeight: AppDimensions.notificationCardMinHeight),
      decoration: BoxDecoration(
        color: isUnread ? cs.primaryContainer.withOpacity(0.25) : cs.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: isUnread ? cs.primary.withOpacity(0.2) : cs.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: _bgColor.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(_icon, color: _bgColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: _NotificationBody(item: item)),
              if (isUnread)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (item.status) {
    'in-progress' => Icons.hourglass_bottom_rounded,
    'resolved'    => Icons.check_circle_rounded,
    'rejected'    => Icons.cancel_rounded,
    'reopened'    => Icons.refresh_rounded,
    _             => Icons.info_rounded,
  };

  Color get _bgColor => switch (item.status) {
    'in-progress' => AppColors.statusInProgress,
    'resolved'    => AppColors.statusResolved,
    'rejected'    => AppColors.statusRejected,
    'reopened'    => Colors.orange,
    _             => AppColors.statusAssigned,
  };
}

class _NotificationBody extends StatelessWidget {
  final NotificationItem item;
  const _NotificationBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface),
            children: [
              TextSpan(text: item.categoryId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: ' issue updated to '),
              TextSpan(text: _statusLabel, style: TextStyle(fontWeight: FontWeight.w700, color: _statusColor)),
            ],
          ),
        ),
        if (item.message.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(item.message, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 4),
        Text(_formatTime(item.timestamp), style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant.withOpacity(0.7))),
      ],
    );
  }

  String get _statusLabel => switch (item.status) {
    'in-progress' => 'In Progress',
    'resolved'    => 'Resolved',
    'rejected'    => 'Rejected',
    'reopened'    => 'Reopened',
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
