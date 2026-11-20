import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/trip_model.dart';

/// Service Local Database menggunakan Hive (Modul 6: Local Storage & NoSQL).
class TripLocalDb {
  static const String boxName = 'trips_box';
  static TripLocalDb? _instance;

  TripLocalDb._internal();

  static TripLocalDb get instance {
    _instance ??= TripLocalDb._internal();
    return _instance!;
  }

  Box get _box => Hive.box(boxName);

  /// Inisialisasi awal Hive Box
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
    await instance.ensureSeeded();
  }

  /// Memastikan ada data awal trip jika database masih kosong
  Future<void> ensureSeeded() async {
    if (_box.isEmpty) {
      final initialTrips = [
        TripModel(
          id: 101,
          tripName: 'Petualangan Sunrise Kaliadem',
          destinationName: 'Bunker Kaliadem',
          startDate: '25 Nov 2026',
          targetBudget: 350000.0,
          notes: 'Membawa jaket tebal, kamera, dan berangkat pukul 05.00 WIB.',
          status: 'Rencana',
          reminderEnabled: true,
          createdAt: DateTime.now().toIso8601String(),
        ),
        TripModel(
          id: 102,
          tripName: 'Wisata Edukasi & Memorial Merapi',
          destinationName: 'Museum Sisa Hartaku & Museum MGM',
          startDate: '28 Nov 2026',
          targetBudget: 200000.0,
          notes: 'Kunjungan keluarga untuk mempelajari sejarah letusan Merapi.',
          status: 'Rencana',
          reminderEnabled: true,
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];

      for (var trip in initialTrips) {
        await _box.put(trip.id, trip.toMap());
      }
      debugPrint('TripLocalDb: Data awal trip berhasil di-seed ke Hive.');
    }
  }

  /// Read (Retrieve) seluruh data trip
  List<TripModel> getAllTrips() {
    final List<TripModel> trips = [];
    for (var key in _box.keys) {
      final raw = _box.get(key);
      if (raw != null && raw is Map) {
        trips.add(TripModel.fromMap(raw));
      }
    }
    // Urutkan dari yang terbaru dibuat
    trips.sort((a, b) => b.id.compareTo(a.id));
    return trips;
  }

  /// Create data trip baru
  Future<void> addTrip(TripModel trip) async {
    await _box.put(trip.id, trip.toMap());
  }

  /// Update data trip yang sudah ada
  Future<void> updateTrip(TripModel trip) async {
    await _box.put(trip.id, trip.toMap());
  }

  /// Delete data trip berdasarkan ID
  Future<void> deleteTrip(int tripId) async {
    await _box.delete(tripId);
  }
}

