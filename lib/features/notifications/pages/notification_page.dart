import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/routes/app_routes.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(() {
            if (ctrl.unreadCount == 0) return const SizedBox.shrink();
            return TextButton.icon(
              onPressed: ctrl.markAllAsRead,
              icon: Icon(Icons.done_all_rounded, size: 16, color: cs.primary),
              label: Text('Mark all read', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return _ShimmerList();
        if (ctrl.notifications.isEmpty) return const _EmptyState();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: ctrl.notifications.length,
          itemBuilder: (_, i) {
            final item = ctrl.notifications[i];
            return NotificationTile(
              item: item,
              onTap: () {
                ctrl.markOneAsRead(item);
                Get.toNamed(AppRoutes.issueDetail.replaceFirst(':id', item.issueId));
              },
            ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.04);
          },
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle),
            child: Icon(Icons.notifications_none_rounded, size: 52, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text('All caught up!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text("You'll be notified when your issue status changes.",
              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          height: 72, margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
