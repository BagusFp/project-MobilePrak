import '../../core/database/trip_local_db.dart';
import '../models/trip_model.dart';

/// Repository untuk mengelola data Trip menggunakan Hive Local Storage (Modul 6 & OOP).
class TripRepository {
  final TripLocalDb _db;

  TripRepository({TripLocalDb? db}) : _db = db ?? TripLocalDb.instance;

  /// Mengambil semua trip dari Hive
  Future<List<TripModel>> getAllTrips() async {
    return _db.getAllTrips();
  }

  /// Menambah trip baru ke Hive (Create)
  Future<void> addTrip(TripModel trip) async {
    await _db.addTrip(trip);
  }

  /// Memperbarui trip di Hive (Update)
  Future<void> updateTrip(TripModel trip) async {
    await _db.updateTrip(trip);
  }

  /// Menghapus trip dari Hive (Delete)
  Future<void> deleteTrip(int tripId) async {
    await _db.deleteTrip(tripId);
  }
}
