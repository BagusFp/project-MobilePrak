import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import 'map_provider.dart';

/// Halaman Layanan Berbasis Lokasi (LBS) & Peta Sederhana (Modul 7: LBS & Geolocator).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MapProvider>();
      await provider.checkPermission();
      if (provider.permissionStatus == LocationPermission.always ||
          provider.permissionStatus == LocationPermission.whileInUse) {
        await provider.fetchUserLocation();
      }
    });
  }

  String _formatPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return 'Diizinkan (Granted)';
      case LocationPermission.denied:
        return 'Belum Diizinkan (Denied)';
      case LocationPermission.deniedForever:
        return 'Ditolak Permanen (Denied Forever)';
      case LocationPermission.unableToDetermine:
        return 'Tidak Diketahui';
    }
  }

  Color _getPermissionColor(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return const Color(0xFF2E7D32);
      case LocationPermission.denied:
        return const Color(0xFFE65100);
      case LocationPermission.deniedForever:
        return AppColors.error;
      case LocationPermission.unableToDetermine:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();
    final pos = mapProv.currentPosition;
    final latLng = mapProv.userLatLng;
    final permission = mapProv.permissionStatus;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Lokasi & LBS Wisatawan'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Perbarui Lokasi',
            onPressed: mapProv.isLoading
                ? null
                : () async {
                    await mapProv.fetchUserLocation();
                    _mapController.move(mapProv.userLatLng, 14.5);
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Tampilan Peta Interaktif Sederhana (FlutterMap)
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: latLng,
                    initialZoom: 13.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.meratrip.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: latLng,
                          width: 50,
                          height: 50,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Tombol Fokus ke Lokasi Pengguna di Peta
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    onPressed: () {
                      _mapController.move(latLng, 14.5);
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
                if (mapProv.isLoading)
                  const Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                              SizedBox(width: 10),
                              Text('Mengambil koordinat GPS...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Panel Info LBS & Koordinat (Modul 7)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.margin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Permission Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security_outlined,
                          color: _getPermissionColor(permission),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status Izin Akses Lokasi (Permission):',
                                style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatPermission(permission),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _getPermissionColor(permission),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (permission != LocationPermission.always &&
                            permission != LocationPermission.whileInUse)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => mapProv.requestPermission(),
                            child: const Text('Minta Izin', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tampilan Koordinat Latitude & Longitude (Modul 7)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD0E8DC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Latitude (Garis Lintang)',
                                style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pos != null ? pos.latitude.toStringAsFixed(6) : '-7.583300',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF04432F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD0E8DC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Longitude (Garis Bujur)',
                                style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pos != null ? pos.longitude.toStringAsFixed(6) : '110.442200',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF04432F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tombol Perbarui Lokasi
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: mapProv.isLoading
                          ? null
                          : () async {
                              await mapProv.fetchUserLocation();
                              _mapController.move(mapProv.userLatLng, 14.5);
                            },
                      icon: const Icon(Icons.my_location),
                      label: const Text(
                        'Perbarui Lokasi Pengguna',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
