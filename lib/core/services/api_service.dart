import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/mock/mock_destinations.dart';
import '../../data/models/destination_model.dart';

/// Service untuk menangani HTTP Request ke REST API (Modul 5: HTTP Request & Parsing JSON).
class ApiService {
  static const String _apiEndpoint =
      'https://xdwkvtwwipbpwkipmtjk.supabase.co/rest/v1/destinations?select=*';
  static const String _apiKey =
      'sb_publishable_b-45mXWI5krktOEAerJDqw_vZ9FKBjd';

  /// Mengambil data daftar destinasi melalui HTTP GET request (Modul 5)
  static Future<List<DestinationModel>> fetchDestinations() async {
    try {
      final response = await http.get(
        Uri.parse(_apiEndpoint),
        headers: {
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        // Parsing response JSON menjadi List object Dart
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        final destinations = jsonList
            .map((item) => DestinationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        debugPrint('ApiService: Berhasil memuat ${destinations.length} destinasi dari API.');
        return destinations;
      } else {
        debugPrint('ApiService HTTP Error: Status code ${response.statusCode}');
        return MockDestinations.destinations;
      }
    } catch (e) {
      debugPrint('ApiService Exception: $e. Menggunakan data cadangan lokal.');
      // Fallback ke data mock lokal jika offline / jaringan bermasalah
      return MockDestinations.destinations;
    }
  }
}
