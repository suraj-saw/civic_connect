import 'package:civic_connect/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../issues/controllers/my_issues_controller.dart';
import '../controllers/home_citizen_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeCitizenController>();
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.4)!],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good to see you 👋', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Help make your city better.', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08),

          const SizedBox(height: 28),
          Text('Quick Actions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: cs.onSurface))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),

          _ActionCard(
            icon: Icons.report_problem_rounded,
            iconBgColor: cs.errorContainer,
            iconColor: cs.onErrorContainer,
            title: 'Report an Issue',
            subtitle: 'Submit a civic complaint with photo & location',
            badge: 'NEW',
            onTap: () async {
              final result = await Get.toNamed(AppRoutes.reportIssue);
              if (result == true) {
                homeCtrl.refresh();
                if (Get.isRegistered<MyIssuesController>()) Get.find<MyIssuesController>().refresh();
              }
            },
          ).animate(delay: 150.ms).fadeIn().slideX(begin: 0.06),
          const SizedBox(height: 12),

          _ActionCard(
            icon: Icons.list_alt_rounded,
            iconBgColor: cs.primaryContainer,
            iconColor: cs.onPrimaryContainer,
            title: 'My Reported Issues',
            subtitle: 'Track status & updates on your submissions',
            onTap: () => Get.toNamed(AppRoutes.myIssues),
          ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.06),

          const SizedBox(height: 28),
          Text('How it Works', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: cs.onSurface))
              .animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 14),

          _StepCard(step: '1', icon: Icons.camera_alt_outlined, title: 'Report', desc: 'Photograph the issue and submit with your location.')
              .animate(delay: 300.ms).fadeIn().slideY(begin: 0.05),
          const SizedBox(height: 8),
          _StepCard(step: '2', icon: Icons.assignment_turned_in_outlined, title: 'Track', desc: 'Get notified as your issue progresses through resolution.')
              .animate(delay: 350.ms).fadeIn().slideY(begin: 0.05),
          const SizedBox(height: 8),
          _StepCard(step: '3', icon: Icons.star_rate_outlined, title: 'Rate', desc: 'Rate the resolution quality and hold officials accountable.')
              .animate(delay: 400.ms).fadeIn().slideY(begin: 0.05),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.iconBgColor, required this.iconColor, required this.title, required this.subtitle, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outline.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(8)),
                            child: Text(badge!, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: cs.onPrimary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String desc;
  const _StepCard({required this.step, required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(step, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: cs.onPrimaryContainer))),
          ),
          const SizedBox(width: 14),
          Icon(icon, color: cs.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
