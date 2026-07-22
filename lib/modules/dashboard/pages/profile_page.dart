import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/pages/login_page.dart';

class MobileProfilePage extends StatelessWidget {
  const MobileProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil & Akun Pengguna',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 16),

              // Avatar Card (Reference Screen 3)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderCard),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryGreen,
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'Admin Lobsense',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'admin@lobsense.com',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'ROLE: ${user?.role.toUpperCase() ?? "ADMIN"}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Info Menu Group Card (Reference Screen 3)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderCard),
                ),
                child: const Column(
                  children: [
                    InfoRow(Icons.smartphone_outlined, 'Versi Aplikasi', 'v1.0.0 (MVP)'),
                    Divider(color: AppTheme.borderCard, height: 24),
                    InfoRow(Icons.dns_outlined, 'Backend Server', 'https://app.lobsens-unpad.web.id'),
                    Divider(color: AppTheme.borderCard, height: 24),
                    InfoRow(Icons.sync_outlined, 'Status Sinkronisasi', '3-Way Realtime Active'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Outlined Red Logout Button (Reference Screen 3)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: AppTheme.dangerRed, size: 18),
                  label: const Text('Keluar dari Akun (Logout)', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.dangerRed, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await auth.logout();
                    navigator.pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGreen),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
      ],
    );
  }
}
