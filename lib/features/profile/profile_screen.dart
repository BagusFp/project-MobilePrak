import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';

/// Halaman Profil Wisatawan (Modul 2, 3: State & Data, Modul 6: Shared Preferences).
class ProfileScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateTab;

  const ProfileScreen({
    super.key,
    this.onNavigateTab,
  });

  void _showEditNameDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController(text: auth.currentUser?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Wisatawan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
            hintText: 'Masukkan nama Anda',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                // Modul 6: Menyimpan perubahan nama ke SharedPreferences
                await auth.updateUserName(newName);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama profil berhasil disimpan ke SharedPreferences!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Akun?'),
        content: const Text('Sesi akun akan diakhiri dan Anda akan kembali ke layar login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) {
                // Modul 4: Navigator.pushReplacement kembali ke Login
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final displayName = user != null && user.name.isNotEmpty ? user.name : 'Wisatawan Merapi';
    final displayEmail = user != null && user.email.isNotEmpty ? user.email : 'wisatawan@meratrip.id';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profil Wisatawan'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.margin),
        children: [
          // 1. Kartu Header Profil
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'W',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayEmail,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showEditNameDialog(context, auth),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Edit Nama',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Info Penyimpanan SharedPreferences (Modul 6)
          Text(
            'DATA & PENYIMPANAN LOKAL',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withAlpha(70)),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.vpn_key_outlined,
                  title: 'Shared Preferences',
                  subtitle: 'Sesi pengguna & nama tersimpan otomatis (XML key-value).',
                ),
                const Divider(height: 16),
                _buildInfoTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Hive Database (trips_box)',
                  subtitle: 'Database lokal NoSQL untuk data rencana perjalanan.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Tentang Aplikasi
          Text(
            'TENTANG APLIKASI',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withAlpha(70)),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.phone_android_rounded,
                  title: 'MeraTrip Praktikum Mobile',
                  subtitle: 'Versi 1.0.0 (Modul 2 - Modul 7 & Konsep OOP)',
                ),
                const Divider(height: 16),
                _buildInfoTile(
                  icon: Icons.landscape_outlined,
                  title: 'Fokus Wisata',
                  subtitle: 'Perencanaan wisata alam lereng Gunung Merapi, Sleman, DIY.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Tombol Logout
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showLogoutDialog(context, auth),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Keluar Akun (Logout)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
