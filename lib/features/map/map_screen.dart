import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/destination_model.dart';
import 'map_provider.dart';

/// Halaman Layanan Berbasis Lokasi (LBS) & Peta Wisatawan (Modul 7: LBS & Geolocator).
/// Mendukung inspeksi lokasi pengguna serta tampilan peta destinasi terpilih.
class MapScreen extends StatefulWidget {
  final DestinationModel? initialDestination;

  const MapScreen({
    super.key,
    this.initialDestination,
  });

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

      // Jika dibuka dari detail destinasi tertentu, langsung pusatkan ke koordinat destinasi tersebut
      if (widget.initialDestination != null) {
        _mapController.move(
          LatLng(widget.initialDestination!.latitude, widget.initialDestination!.longitude),
          14.5,
        );
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
    final userLatLng = mapProv.userLatLng;
    final permission = mapProv.permissionStatus;

    final dest = widget.initialDestination;
    final destLatLng = dest != null ? LatLng(dest.latitude, dest.longitude) : null;
    final centerLatLng = destLatLng ?? userLatLng;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(dest != null ? 'Peta: ${dest.name}' : 'Lokasi & LBS Wisatawan'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Perbarui Lokasi GPS',
            onPressed: mapProv.isLoading
                ? null
                : () async {
                    await mapProv.fetchUserLocation();
                    if (dest == null) {
                      _mapController.move(mapProv.userLatLng, 14.5);
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Tampilan Peta Interaktif (FlutterMap)
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centerLatLng,
                    initialZoom: dest != null ? 14.5 : 13.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.meratrip.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marker Destinasi (jika tersedia)
                        if (dest != null && destLatLng != null)
                          Marker(
                            point: destLatLng,
                            width: 150,
                            height: 68,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4),
                                    ],
                                  ),
                                  child: Text(
                                    dest.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFFC62828),
                                  size: 34,
                                ),
                              ],
                            ),
                          ),

                        // Marker Lokasi Pengguna (User GPS)
                        Marker(
                          point: userLatLng,
                          width: 50,
                          height: 50,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1976D2),
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

                // Floating Action Buttons di atas Peta
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (destLatLng != null) ...[
                        FloatingActionButton.small(
                          heroTag: 'dest_btn',
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFC62828),
                          tooltip: 'Pusatkan ke Destinasi',
                          onPressed: () {
                            _mapController.move(destLatLng, 15.0);
                          },
                          child: const Icon(Icons.pin_drop),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FloatingActionButton.small(
                        heroTag: 'gps_btn',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        tooltip: 'Pusatkan ke Lokasi Pengguna',
                        onPressed: () {
                          _mapController.move(userLatLng, 14.5);
                        },
                        child: const Icon(Icons.my_location),
                      ),
                    ],
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
                  // Kartu Destinasi Terpilih (jika ada)
                  if (dest != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF81C784)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.place, color: Color(0xFF2E7D32), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dest.name,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${dest.elevationMdpl} mdpl',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dest.address,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Titik Koordinat: ${dest.latitude.toStringAsFixed(6)}, ${dest.longitude.toStringAsFixed(6)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

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

                  // Tampilan Koordinat Pengguna Latitude & Longitude (Modul 7)
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
                                'Latitude (Pengguna)',
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
                                'Longitude (Pengguna)',
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
