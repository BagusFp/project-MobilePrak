import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/trip_model.dart';

/// Service Local Database menggunakan Hive (Modul 6: Local Storage CRUD).
/// Menyimpan data trip dan relasinya secara persisten ke Hive Box 'trips_box'.
class TripLocalDb {
  static const String boxName = 'trips_box';
  static TripLocalDb? _instance;
  static bool _isInitialized = false;
  final Map<int, Map<String, dynamic>> _inMemoryFallback = {};

  TripLocalDb._internal();

  static TripLocalDb get instance {
    _instance ??= TripLocalDb._internal();
    return _instance!;
  }

  /// Inisialisasi awal Hive Box saat aplikasi startup
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _isInitialized = true;
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
    } catch (e) {
      debugPrint('TripLocalDb.init error: $e');
    }
  }

  Future<Box?> _getBox() async {
    if (!_isInitialized && !Hive.isBoxOpen(boxName)) {
      return null;
    }
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName);
      }
      return await Hive.openBox(boxName);
    } catch (e) {
      debugPrint('TripLocalDb: Hive box error ($e)');
      return null;
    }
  }

  /// Create: Menambahkan trip baru ke Hive
  Future<void> addTrip(TripModel trip) async {
    if (trip.id == null) return;
    _inMemoryFallback[trip.id!] = trip.toMap();
    try {
      final box = await _getBox();
      if (box != null && box.isOpen) {
        await box.put(trip.id, trip.toMap());
      }
    } catch (e) {
      debugPrint('TripLocalDb addTrip error: $e');
    }
  }

  /// Read: Mengambil seluruh trip yang tersimpan di Hive
  Future<List<TripModel>> getAllTrips() async {
    final List<TripModel> trips = [];
    try {
      final box = await _getBox();
      if (box != null && box.isOpen) {
        for (var key in box.keys) {
          try {
            final raw = box.get(key);
            if (raw != null && raw is Map) {
              trips.add(TripModel.fromMap(Map<String, dynamic>.from(raw)));
            }
          } catch (e) {
            debugPrint('TripLocalDb error parsing trip $key: $e');
          }
        }
      } else {
        for (var map in _inMemoryFallback.values) {
          trips.add(TripModel.fromMap(map));
        }
      }
    } catch (e) {
      debugPrint('TripLocalDb getAllTrips error: $e');
    }
    trips.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return trips;
  }

  /// Update: Memperbarui trip di Hive
  Future<void> updateTrip(TripModel trip) async {
    if (trip.id == null) return;
    _inMemoryFallback[trip.id!] = trip.toMap();
    try {
      final box = await _getBox();
      if (box != null && box.isOpen) {
        await box.put(trip.id, trip.toMap());
      }
    } catch (e) {
      debugPrint('TripLocalDb updateTrip error: $e');
    }
  }

  /// Delete: Menghapus trip dari Hive berdasarkan ID
  Future<void> deleteTrip(int tripId) async {
    _inMemoryFallback.remove(tripId);
    try {
      final box = await _getBox();
      if (box != null && box.isOpen) {
        await box.delete(tripId);
      }
    } catch (e) {
      debugPrint('TripLocalDb deleteTrip error: $e');
    }
  }
}

