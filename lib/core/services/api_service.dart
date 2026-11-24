import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../data/models/destination_model.dart';
import 'supabase_service.dart';

/// Service untuk menangani query eksternal online (Supabase, OSRM Route, OpenStreetMap Nominatim).
/// Menggantikan backend Laravel perantara dengan koneksi langsung ke Supabase Cloud.
class ApiService {
  /// Mengambil daftar destinasi terverifikasi langsung dari Supabase Cloud
  static Future<List<DestinationModel>?> fetchVerifiedDestinations() async {
    try {
      final supabaseList = await SupabaseService().fetchDestinations();
      if (supabaseList != null && supabaseList.isNotEmpty) {
        return supabaseList;
      }
    } catch (e) {
      debugPrint('ApiService.fetchVerifiedDestinations via Supabase error: $e');
    }
    return null;
  }

  /// Menghitung rute navigasi jalan via public Open Source Routing Machine (OSRM)
  static Future<Map<String, dynamic>?> getOsrmRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$startLng,$startLat;$endLng,$endLat'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          final List<LatLng> points = coordinates.map((coord) {
            final c = coord as List;
            return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
          }).toList();

          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSeconds = (route['duration'] as num).toDouble();

          return {
            'coordinates': points,
            'points': points,
            'distance_km': (distanceMeters / 1000.0),
            'duration_minutes': (durationSeconds / 60.0).round(),
          };
        }
      }
    } catch (e) {
      debugPrint('OSRM routing direct error: $e');
    }
    return null;
  }
}
