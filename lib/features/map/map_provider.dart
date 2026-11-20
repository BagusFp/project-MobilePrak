import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Provider untuk Location-Based Services (LBS) dan Geolocator (Modul 7).
class MapProvider extends ChangeNotifier {
  Position? _currentPosition;
  LocationPermission _permissionStatus = LocationPermission.denied;
  bool _isLoading = false;
  String? _errorMessage;

  // Default titik tengah Merapi jika lokasi belum didapatkan
  static const LatLng defaultMerapiLocation = LatLng(-7.5833, 110.4422);

  Position? get currentPosition => _currentPosition;
  LocationPermission get permissionStatus => _permissionStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LatLng get userLatLng {
    if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    return defaultMerapiLocation;
  }

  /// Memeriksa status izin lokasi saat ini (Modul 7: Location Permission)
  Future<void> checkPermission() async {
    try {
      _permissionStatus = await Geolocator.checkPermission();
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking permission: $e');
    }
  }

  /// Meminta izin akses lokasi kepada pengguna (Modul 7)
  Future<bool> requestPermission() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Layanan GPS / Lokasi pada perangkat belum diaktifkan.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _permissionStatus = await Geolocator.requestPermission();
      notifyListeners();

      if (_permissionStatus == LocationPermission.always ||
          _permissionStatus == LocationPermission.whileInUse) {
        await fetchUserLocation();
        return true;
      } else {
        _errorMessage = 'Izin lokasi tidak diberikan oleh pengguna.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Gagal meminta izin lokasi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mengambil koordinat lokasi terkini (Latitude & Longitude) pengguna (Modul 7: LBS)
  Future<void> fetchUserLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _currentPosition = position;
      _permissionStatus = await Geolocator.checkPermission();
    } catch (e) {
      _errorMessage = 'Gagal mengambil koordinat lokasi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
