import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/notification_service.dart';
import 'notification_provider.dart';

/// Halaman Notifikasi & Pengingat (Modul 7: Immediate & Scheduled Notifications).
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  void _triggerImmediateNotification(BuildContext context) async {
    await NotificationService().showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '🔔 Uji Notifikasi Langsung MeraTrip',
      body: 'Notifikasi instan berhasil dipicu dan tampil di bilah status HP Anda!',
      tag: 'Immediate Notification',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi langsung berhasil dipicu ke status bar HP!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _triggerScheduledNotification(BuildContext context) async {
    final triggerTime = DateTime.now().add(const Duration(seconds: 5));

    await NotificationService().scheduleTripReminderAtTime(
      tripId: 8888,
      tripTitle: 'Simulasi Berangkat Bunker Kaliadem',
      triggerTime: triggerTime,
      startDestinationName: 'Bunker Kaliadem',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi dijadwalkan! Akan muncul dalam 5 detik...'),
          backgroundColor: Color(0xFFE89005),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Notifikasi & Pengingat'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
              tooltip: 'Tandai Semua Dibaca',
              onPressed: () => notifProvider.markAllAsRead(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Panel Pengujian Notifikasi (Modul 7)
          Padding(
            padding: const EdgeInsets.all(AppDimensions.margin),
            child: Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Uji Coba Notifikasi (Modul 7)',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Uji coba fitur notifikasi lokal Android: notifikasi instan dan notifikasi terjadwal (scheduled).',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Tombol Immediate Notification
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _triggerImmediateNotification(context),
                          icon: const Icon(Icons.flash_on, size: 16),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Notif Instan', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Tombol Scheduled Notification
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE89005),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _triggerScheduledNotification(context),
                          icon: const Icon(Icons.alarm, size: 16),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Notif Jadwal (5s)', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Daftar Riwayat Notifikasi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RIWAYAT NOTIFIKASI',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '${notifications.length} Pesan',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.outline),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada notifikasi terkirim.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tekan tombol uji coba di atas untuk mencoba.',
                          style: TextStyle(fontSize: 12, color: AppColors.outline),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.outlineVariant.withAlpha(70)),
                        ),
                        color: item.isRead
                            ? AppColors.surfaceContainerLowest
                            : const Color(0xFFF0FDF4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: item.isRead
                                ? AppColors.secondaryContainer
                                : AppColors.primaryContainer,
                            child: Icon(
                              item.category == 'volcano'
                                  ? Icons.warning_amber_rounded
                                  : Icons.notifications_active_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!item.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.outlineVariant.withAlpha(60),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.tag,
                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    item.timeAgo,
                                    style: const TextStyle(fontSize: 10, color: AppColors.outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => notifProvider.markAsRead(item.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
