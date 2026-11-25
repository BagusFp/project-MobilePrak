import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/geo_helper.dart';
import '../../data/mock/mock_destinations.dart';
import '../../data/models/destination_model.dart';

/// [OOP - Encapsulation & Inheritance]
/// MapProvider mewarisi ChangeNotifier dan membungkus state lokasi dengan field private (_) + getter public.
class MapProvider extends ChangeNotifier {
  // State Navigasi & Map (private agar hanya bisa diubah lewat method terkontrol)
  DestinationModel? _selectedDestination;
  String _viewMode = 'map'; // 'map' atau 'list'
  double _userLat = GeoHelper.userDefaultLat;
  double _userLng = GeoHelper.userDefaultLng;

  // Real-time GPS Tracking State
  bool _isLocating = false;
  bool _hasLiveGpsFix = false;
  String? _locationStatusMessage;
  double? _gpsAccuracyMeters;
  String _mapStyle = 'standard'; // 'standard', 'topo', 'voyager'

  // OSRM Routing State (FR & User Poin 1)
  bool _isLoadingRoute = false;
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  int? _routeDurationMinutes;
  String? _routeError;

  MapProvider() {
    // Default seleksi: Bunker Kaliadem
    if (MockDestinations.destinations.isNotEmpty) {
      _selectedDestination = MockDestinations.destinations.first;
    }
  }

  // Getters
  DestinationModel? get selectedDestination => _selectedDestination;
  String get viewMode => _viewMode;
  double get userLat => _userLat;
  double get userLng => _userLng;

  bool get isLocating => _isLocating;
  bool get hasLiveGpsFix => _hasLiveGpsFix;
  String? get locationStatusMessage => _locationStatusMessage;
  double? get gpsAccuracyMeters => _gpsAccuracyMeters;
  String get mapStyle => _mapStyle;

  bool get isLoadingRoute => _isLoadingRoute;
  List<LatLng> get routePoints => _routePoints;
  double? get routeDistanceKm => _routeDistanceKm;
  int? get routeDurationMinutes => _routeDurationMinutes;
  String? get routeError => _routeError;

  /// Destinasi yang diurutkan berdasarkan kedekatan LBS dengan pengguna
  List<DestinationModel> get destinationsSortedByDistance {
    final list = List<DestinationModel>.from(MockDestinations.destinations);
    list.sort((a, b) {
      final distA = GeoHelper.distanceToUser(a.latitude, a.longitude, userLat: _userLat, userLng: _userLng);
      final distB = GeoHelper.distanceToUser(b.latitude, b.longitude, userLat: _userLat, userLng: _userLng);
      return distA.compareTo(distB);
    });
    return list;
  }

  /// Memilih destinasi aktif di peta (dapat null jika ditutup)
  void selectDestination(DestinationModel? dest) {
    _selectedDestination = dest;
    notifyListeners();
  }

  /// Beralih antara mode tampilan 'map' dan 'list'
  void setViewMode(String mode) {
    _viewMode = mode;
    notifyListeners();
  }

  /// Toggle antara mode 'map' dan 'list'
  void toggleViewMode() {
    _viewMode = _viewMode == 'map' ? 'list' : 'map';
    notifyListeners();
  }

  /// [MODUL 7 - LBS (Location-Based Services)]
  /// Cek status layanan GPS, meminta permission lokasi, lalu mengambil koordinat lat/lng via Geolocator.
  Future<bool> fetchLiveLocation() async {
    _isLocating = true;
    _locationStatusMessage = 'Menghubungkan ke sensor GPS ponsel...';
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLocating = false;
        _locationStatusMessage = 'Layanan GPS perangkat belum diaktifkan.';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isLocating = false;
          _locationStatusMessage = 'Izin lokasi GPS ditolak oleh pengguna.';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLocating = false;
        _locationStatusMessage = 'Izin lokasi ditolak permanen di setelan HP.';
        notifyListeners();
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _userLat = position.latitude;
      _userLng = position.longitude;
      _hasLiveGpsFix = true;
      _gpsAccuracyMeters = position.accuracy;
      _locationStatusMessage = 'Lokasi asli ponsel aktif: ${_userLat.toStringAsFixed(4)}, ${_userLng.toStringAsFixed(4)} (±${position.accuracy.toStringAsFixed(0)}m)';
      _isLocating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLocating = false;
      _locationStatusMessage = 'GPS tidak merespons ($e). Memakai titik Kaliurang.';
      notifyListeners();
      return false;
    }
  }

  /// Reset/recenter ke titik acuan Pos Retribusi Kaliurang
  void recenterUserLocation() {
    _userLat = GeoHelper.userDefaultLat;
    _userLng = GeoHelper.userDefaultLng;
    _locationStatusMessage = 'Posisi diatur ke Pos Retribusi Kaliurang.';
    notifyListeners();
  }

  /// Atur lokasi secara manual (berguna untuk simulasi / pengujian)
  void setUserLocationManually(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    _hasLiveGpsFix = true;
    notifyListeners();
  }

  /// Beralih gaya tampilan peta OpenStreetMap
  void setMapStyle(String style) {
    _mapStyle = style;
    notifyListeners();
  }

  /// Mengambil rute mengemudi nyata dari lokasi pengguna ke destinasi via OSRM
  Future<void> fetchRouteToDestination(DestinationModel dest) async {
    _isLoadingRoute = true;
    _routeError = null;
    notifyListeners();

    try {
      final res = await ApiService.getOsrmRoute(
        startLat: _userLat,
        startLng: _userLng,
        endLat: dest.latitude,
        endLng: dest.longitude,
      );

      if (res != null && res['coordinates'] is List && (res['coordinates'] as List).isNotEmpty) {
        _routePoints = List<LatLng>.from(res['coordinates'] as List);
        _routeDistanceKm = (res['distance_km'] as num?)?.toDouble();
        _routeDurationMinutes = (res['duration_minutes'] as num?)?.round();
      } else {
        _routePoints = [LatLng(_userLat, _userLng), LatLng(dest.latitude, dest.longitude)];
        _routeDistanceKm = GeoHelper.distanceToUser(dest.latitude, dest.longitude, userLat: _userLat, userLng: _userLng);
        _routeDurationMinutes = (_routeDistanceKm! / 25 * 60).round();
      }
    } catch (e) {
      _routeError = 'Gagal memuat rute OSRM: $e';
      _routePoints = [LatLng(_userLat, _userLng), LatLng(dest.latitude, dest.longitude)];
    } finally {
      _isLoadingRoute = false;
      notifyListeners();
    }
  }

  /// Menghapus rute aktif di peta
  void clearRoute() {
    _routePoints = [];
    _routeDistanceKm = null;
    _routeDurationMinutes = null;
    _routeError = null;
    notifyListeners();
  }
}
