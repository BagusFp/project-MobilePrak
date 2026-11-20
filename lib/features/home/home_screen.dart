import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_network_image.dart';
import '../auth/auth_provider.dart';
import '../explore/destination_detail_screen.dart';
import '../explore/destination_provider.dart';
import '../map/map_screen.dart';
import '../notification/notification_screen.dart';
import '../trip/create_trip_screen.dart';

/// Halaman Beranda (Home) Aplikasi MeraTrip (Modul 2, 3: State & Data, Modul 4: Navigation).
class HomeScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final destProvider = context.watch<DestinationProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final userName = user != null && user.name.trim().isNotEmpty
        ? user.name.trim().toUpperCase()
        : 'WISATAWAN';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Greeting Section
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.margin,
                  AppDimensions.spaceMd,
                  AppDimensions.margin,
                  AppDimensions.spaceMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HALO, $userName 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mau menjelajah Merapi?',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rencanakan petualangan wisatamu dengan cerdas & aman.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Status Aktivitas Merapi Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE89005),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'STATUS AKTIVITAS',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Merapi Level II (Waspada)',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Kawasan wisata Kaliurang & Cangkringan terpantau aman.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Grid Menu Shortcut Navigasi Utama (Modul 2: Grid/Row Layout, Modul 4: Navigator)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MENU UTAMA',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Shortcut 1: Explore Destinasi
                        Expanded(
                          child: _buildShortcutCard(
                            context: context,
                            icon: Icons.explore_outlined,
                            iconColor: const Color(0xFF04432F),
                            iconBgColor: const Color(0xFFD7F5E5),
                            title: 'Explore',
                            subtitle: 'Daftar Wisata',
                            onTap: () {
                              if (onNavigateTab != null) {
                                onNavigateTab!(1);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Shortcut 2: My Trip (Kelola Perjalanan)
                        Expanded(
                          child: _buildShortcutCard(
                            context: context,
                            icon: Icons.luggage_outlined,
                            iconColor: const Color(0xFF1E88E5),
                            iconBgColor: const Color(0xFFE3F2FD),
                            title: 'My Trip',
                            subtitle: 'Rencana Trip',
                            onTap: () {
                              if (onNavigateTab != null) {
                                onNavigateTab!(2);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Shortcut 3: Lokasi & LBS
                        Expanded(
                          child: _buildShortcutCard(
                            context: context,
                            icon: Icons.location_on_outlined,
                            iconColor: const Color(0xFFE65100),
                            iconBgColor: const Color(0xFFFFF3E0),
                            title: 'Lokasi & LBS',
                            subtitle: 'Koordinat GPS',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MapScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Shortcut 4: Notifikasi
                        Expanded(
                          child: _buildShortcutCard(
                            context: context,
                            icon: Icons.notifications_none_rounded,
                            iconColor: const Color(0xFF6A1B9A),
                            iconBgColor: const Color(0xFFF3E5F5),
                            title: 'Notifikasi',
                            subtitle: 'Pengingat Wisata',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Perencana Trip Cepat Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_task_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Buat Rencana Trip Baru',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rencanakan destinasi lereng Merapi dan simpan anggaran secara lokal dengan Hive.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateTripScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Mulai Rencana Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Section Header: Rekomendasi Destinasi Utama
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'REKOMENDASI DESTINASI',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    InkWell(
                      onTap: () => onNavigateTab?.call(1),
                      child: Text(
                        'Lihat Semua',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 6. Horizontal List Rekomendasi Destinasi (Modul 2: ListView.builder horizontal)
              SizedBox(
                height: 220,
                child: destProvider.allDestinations.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                        itemCount: destProvider.allDestinations.take(5).length,
                        itemBuilder: (context, index) {
                          final dest = destProvider.allDestinations[index];
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 14),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: AppColors.outlineVariant.withAlpha(80)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              color: AppColors.surfaceContainerLowest,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DestinationDetailScreen(destination: dest),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppNetworkImage(
                                      imageUrl: dest.imageUrl,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dest.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  ' mdpl',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  dest.formattedTicketPrice,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _buildShortcutCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
