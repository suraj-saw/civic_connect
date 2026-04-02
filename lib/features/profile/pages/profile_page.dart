import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/repositories/auth_reporsitory.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});
  final _auth = AuthRepository();

  Future<void> _handleLogout(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _auth.signOut();
      } catch (e) {
        Get.snackbar("Error", "Failed to sign out. Please try again.", snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final cs = Theme.of(context).colorScheme;

    if (uid == null) {
      return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Not signed in'),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _auth.signOut, child: const Text('Go to Sign In')),
      ])));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Profile not found.')));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name     = data['name']  as String? ?? 'User';
        final email    = data['email'] as String? ?? '';
        final phone    = data['phone'] as String? ?? '';
        final role     = (data['role'] as String? ?? 'citizen').toUpperCase();
        final verified = data['phoneVerified'] == true;
        final initial  = name.isNotEmpty ? name[0].toUpperCase() : 'U';

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Hero header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 36),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.4)!],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: Center(child: Text(initial, style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white))),
                      ),
                      const SizedBox(height: 14),
                      Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(role, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      Text('Account Info', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurfaceVariant))
                          .animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 10),

                      _InfoCard(children: [
                        _InfoRow(icon: Icons.person_outline_rounded, label: 'Full Name', value: name, cs: cs),
                        Divider(height: 1, color: cs.outline.withOpacity(0.1)),
                        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email, cs: cs),
                        Divider(height: 1, color: cs.outline.withOpacity(0.1)),
                        _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: phone, cs: cs),
                        Divider(height: 1, color: cs.outline.withOpacity(0.1)),
                        _InfoRow(
                          icon: verified ? Icons.verified_user_outlined : Icons.warning_amber_outlined,
                          label: 'Phone Verified',
                          value: verified ? 'Verified' : 'Not Verified',
                          cs: cs,
                          valueColor: verified ? Colors.green : Colors.orange,
                        ),
                      ]).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),

                      const SizedBox(height: 28),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.logout_rounded, color: cs.error),
                          label: Text('Sign Out', style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: cs.error.withOpacity(0.6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _handleLogout(context),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.cs, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? cs.onSurface)),
            ],
          ),
        ],
      ),
    );
  }
}
