import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/destination_model.dart';
import 'map_provider.dart';

/// Halaman Layanan Berbasis Lokasi (LBS) & Peta Wisatawan (Modul 7: LBS & Geolocator).
/// Menghubungkan titik lokasi pengguna saat ini ke titik destinasi tujuan dengan garis rute interaktif.
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

      // Jika ada destinasi awal, pusatkan peta ke destinasi atau sesuaikan agar keduanya terlihat
      if (widget.initialDestination != null) {
        final dest = widget.initialDestination!;
        final destLatLng = LatLng(dest.latitude, dest.longitude);
        final userLatLng = provider.userLatLng;

        // Pusatkan ke titik tengah antara user dan destinasi jika koordinat berbeda
        if ((destLatLng.latitude - userLatLng.latitude).abs() > 0.001 ||
            (destLatLng.longitude - userLatLng.longitude).abs() > 0.001) {
          _fitUserAndDestination(userLatLng, destLatLng);
        } else {
          _mapController.move(destLatLng, 14.5);
        }
      }
    });
  }

  void _fitUserAndDestination(LatLng userLatLng, LatLng destLatLng) {
    try {
      final bounds = LatLngBounds(userLatLng, destLatLng);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (_) {
      _mapController.move(destLatLng, 13.5);
    }
  }

  Future<void> _openGoogleMapsDirections(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka aplikasi Google Maps')),
        );
      }
    }
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

    // Hitung jarak nyata dari lokasi pengguna ke destinasi
    final double distanceInMeters = destLatLng != null
        ? Geolocator.distanceBetween(
            userLatLng.latitude,
            userLatLng.longitude,
            destLatLng.latitude,
            destLatLng.longitude,
          )
        : 0.0;
    final String distanceKm = (distanceInMeters / 1000).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(dest != null ? 'Peta & Rute: ${dest.name}' : 'Lokasi & LBS Wisatawan'),
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
          // 1. Tampilan Peta Interaktif (FlutterMap) dengan Rute Garis (Polyline)
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centerLatLng,
                    initialZoom: dest != null ? 13.5 : 13.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.meratrip.app',
                    ),

                    // Garis Penghubung Rute Titik Saat Ini ke Destinasi (Polyline)
                    if (destLatLng != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [userLatLng, destLatLng],
                            strokeWidth: 4.0,
                            color: const Color(0xFF2E7D32),
                            borderStrokeWidth: 2.0,
                            borderColor: Colors.white,
                          ),
                        ],
                      ),

                    // Layer Marker
                    MarkerLayer(
                      markers: [
                        // Marker Destinasi Tujuan (jika ada)
                        if (dest != null && destLatLng != null)
                          Marker(
                            point: destLatLng,
                            width: 150,
                            height: 70,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC62828),
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
                                  size: 36,
                                ),
                              ],
                            ),
                          ),

                        // Marker Lokasi Terkini Pengguna (GPS)
                        Marker(
                          point: userLatLng,
                          width: 120,
                          height: 65,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 3),
                                  ],
                                ),
                                child: const Text(
                                  'Lokasi Anda',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.person_pin_circle,
                                color: Color(0xFF1976D2),
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating Action Buttons di atas Peta untuk Kontrol Rute
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (destLatLng != null) ...[
                        FloatingActionButton.small(
                          heroTag: 'fit_route_btn',
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2E7D32),
                          tooltip: 'Tampilkan Seluruh Rute',
                          onPressed: () => _fitUserAndDestination(userLatLng, destLatLng),
                          child: const Icon(Icons.route),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'dest_btn',
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFC62828),
                          tooltip: 'Pusatkan ke Destinasi',
                          onPressed: () => _mapController.move(destLatLng, 15.0),
                          child: const Icon(Icons.pin_drop),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FloatingActionButton.small(
                        heroTag: 'gps_btn',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1976D2),
                        tooltip: 'Pusatkan ke Lokasi Saya',
                        onPressed: () => _mapController.move(userLatLng, 15.0),
                        child: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),

                // Indikator Jarak Rute Mengambang (Floating Banner)
                if (dest != null)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Jarak ke ${dest.name}: $distanceKm km',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => _openGoogleMapsDirections(dest.latitude, dest.longitude),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.open_in_new, size: 12, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Maps',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (mapProv.isLoading)
                  const Positioned(
                    top: 60,
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

          // 2. Panel Info LBS, Koordinat, & Panduan Rute (Modul 7)
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Koordinat: ${dest.latitude.toStringAsFixed(6)}, ${dest.longitude.toStringAsFixed(6)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: const Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Jarak: $distanceKm km',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
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

                  // Tombol Aksi: Buka Navigasi Luar & Perbarui Lokasi
                  Row(
                    children: [
                      if (dest != null) ...[
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _openGoogleMapsDirections(dest.latitude, dest.longitude),
                              icon: const Icon(Icons.navigation_outlined, size: 18),
                              label: const Text('Buka Maps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: SizedBox(
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
                            icon: const Icon(Icons.my_location, size: 18),
                            label: const Text(
                              'Update Lokasi',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
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
