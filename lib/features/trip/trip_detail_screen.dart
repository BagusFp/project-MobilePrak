import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_network_image.dart';
import '../../data/models/trip_model.dart';
import '../explore/destination_detail_screen.dart';
import '../map/map_screen.dart';
import 'create_trip_screen.dart';
import 'trip_provider.dart';

/// Halaman Detail Rencana Trip Multi-Destinasi (Modul 2, 3, 4: Passing Data, Modul 6: Hive, Modul 7: Notifikasi).
/// Menyediakan fitur checklist status kunjungan destinasi ("sudah ke situ") serta navigasi rute peta langsung.
class TripDetailScreen extends StatelessWidget {
  final TripModel trip;

  const TripDetailScreen({
    super.key,
    required this.trip,
  });

  void _showDeleteDialog(BuildContext context, TripModel currentTrip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Rencana Trip?'),
        content: Text('Apakah Anda yakin ingin menghapus "${currentTrip.tripName}" dari penyimpanan lokal?'),
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
              await context.read<TripProvider>().deleteTrip(currentTrip.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trip berhasil dihapus dari Hive.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _scheduleReminder(BuildContext context, TripModel currentTrip) async {
    // Menjadwalkan notifikasi pengingat trip (Modul 7)
    await NotificationService().showInstantNotification(
      id: currentTrip.id,
      title: '🔔 Pengingat Wisata: ${currentTrip.tripName}',
      body: 'Perjalanan menuju ${currentTrip.destinationName} dijadwalkan pada ${currentTrip.startDate}. Siapkan perlengkapanmu!',
      payload: '/trip/${currentTrip.id}',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengingat trip "${currentTrip.tripName}" telah dikirimkan ke bilah notifikasi!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    // Dapatkan data trip terkini dari provider jika ada perubahan status ("sudah ke situ")
    final currentTrip = tripProvider.trips.firstWhere(
      (t) => t.id == trip.id,
      orElse: () => trip,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Detail Rencana Trip'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit Trip',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateTripScreen(existingTrip: currentTrip),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Hapus Trip',
            onPressed: () => _showDeleteDialog(context, currentTrip),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kartu Ringkasan Trip & Status
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentTrip.isCompleted
                              ? const Color(0xFF81C784)
                              : Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentTrip.status.toUpperCase(),
                          style: TextStyle(
                            color: currentTrip.isCompleted ? const Color(0xFF1B5E20) : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentTrip.totalDestinations} Destinasi',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentTrip.tripName,
                    style: AppTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.route_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          currentTrip.destinationsSummary,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Bar Progres Kunjungan Destinasi ("Saat Sudah ke Situ")
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progres Kunjungan Destinasi',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${currentTrip.visitedCount}/${currentTrip.totalDestinations} Selesai (${(currentTrip.progressPercent * 100).toInt()}%)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: currentTrip.progressPercent,
                      backgroundColor: AppColors.outlineVariant.withAlpha(60),
                      color: const Color(0xFF2E7D32),
                      minHeight: 8,
                    ),
                  ),
                  if (currentTrip.visitedCount == currentTrip.totalDestinations &&
                      currentTrip.totalDestinations > 0) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
                        SizedBox(width: 6),
                        Text(
                          'Semua destinasi telah dikunjungi! Perjalanan tuntas.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Daftar Seluruh Destinasi dalam Trip dengan Tombol Checklist "Sudah ke Situ"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rangkaian Destinasi (${currentTrip.totalDestinations})',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tandai yang sudah dikunjungi',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (currentTrip.destinations.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
                ),
                child: const Text(
                  'Belum ada destinasi yang ditambahkan ke trip ini.',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentTrip.destinations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final destItem = currentTrip.destinations[index];
                  final isVisited = destItem.isVisited;

                  return Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isVisited
                            ? const Color(0xFF81C784)
                            : AppColors.outlineVariant.withAlpha(70),
                        width: isVisited ? 1.5 : 1,
                      ),
                    ),
                    color: isVisited
                        ? const Color(0xFFF1F8F5)
                        : AppColors.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Nomor Urutan
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isVisited ? const Color(0xFF2E7D32) : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Thumbnail Gambar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppNetworkImage(
                                  imageUrl: destItem.imageUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info Destinasi
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      destItem.name,
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${destItem.category} • ${destItem.elevationMdpl} mdpl',
                                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),

                              // Tombol Checklist "Sudah ke Situ"
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () async {
                                  await tripProvider.toggleDestinationVisited(
                                    tripId: currentTrip.id,
                                    destinationId: destItem.id,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          !isVisited
                                              ? '✓ "${destItem.name}" ditandai sudah dikunjungi (sudah ke situ)!'
                                              : 'Status kunjungan "${destItem.name}" diubah kembali ke belum dikunjungi.',
                                        ),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: !isVisited ? const Color(0xFF2E7D32) : AppColors.outline,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isVisited
                                        ? const Color(0xFFE8F5E9)
                                        : AppColors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isVisited
                                          ? const Color(0xFF2E7D32)
                                          : AppColors.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isVisited ? Icons.check_circle : Icons.radio_button_unchecked,
                                        size: 16,
                                        color: isVisited ? const Color(0xFF2E7D32) : AppColors.outline,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isVisited ? 'Sudah ke situ' : 'Belum',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isVisited ? const Color(0xFF2E7D32) : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),

                          // Tombol Aksi Cepat: Peta Rute & Detail Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: AppColors.primary,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MapScreen(
                                        initialDestination: destItem.toDestinationModel(),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.directions_outlined, size: 16),
                                label: const Text('Peta Rute', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: AppColors.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DestinationDetailScreen(
                                        destination: destItem.toDestinationModel(),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.info_outline, size: 16),
                                label: const Text('Detail', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),

            // 4. Detail Parameter Trip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal Berangkat',
                    value: currentTrip.startDate,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Target Anggaran',
                    value: currentTrip.formattedBudget,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.map_outlined,
                    label: 'Total Destinasi',
                    value: '${currentTrip.totalDestinations} Destinasi Wisata',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.storage_rounded,
                    label: 'Database Penyimpanan',
                    value: 'Hive Local Storage (Box: trips_box)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Catatan Trip
            Text(
              'Catatan & Perlengkapan',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
              ),
              child: Text(
                currentTrip.notes.isNotEmpty ? currentTrip.notes : 'Tidak ada catatan tambahan untuk trip ini.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 6. Tombol Kirim Pengingat Notifikasi (Modul 7)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE89005),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _scheduleReminder(context, currentTrip),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text(
                  'Uji Pengingat Notifikasi Trip',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
