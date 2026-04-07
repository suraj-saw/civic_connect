import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_routes.dart';
import '../../controllers/home_admin_controller.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeAdminController>();
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());

        final name = ctrl.adminName.value.isEmpty ? 'Admin' : ctrl.adminName.value;
        final initial = name.isEmpty ? 'A' : name[0].toUpperCase();

        return SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.4)!],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32, backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(initial, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(height: 14),
                    Text(name, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(ctrl.adminEmail.value, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(ctrl.adminDept.value.toUpperCase(),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 12),
              _DrawerItem(icon: Icons.dashboard_rounded, label: 'Dashboard', onTap: () => Navigator.pop(context))
                  .animate(delay: 50.ms).fadeIn().slideX(begin: -0.06),
              _DrawerItem(
                icon: Icons.smart_toy_rounded,
                label: 'CivicBot Admin',
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(AppRoutes.adminChatbot);
                },
              ).animate(delay: 80.ms).fadeIn().slideX(begin: -0.06),

              const Spacer(),
              const Divider(indent: 16, endIndent: 16),
              _DrawerItem(
                icon: Icons.logout_rounded, label: 'Sign Out', color: cs.error,
                onTap: () async { Navigator.pop(context); await ctrl.signOut(); },
              ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.06),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface;
    return ListTile(
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: c)),
      onTap: onTap,
    );
  }
}
