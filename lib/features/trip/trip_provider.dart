import 'package:flutter/foundation.dart';
import '../../data/models/trip_model.dart';
import '../../data/repositories/trip_repository.dart';

/// Provider untuk manajemen state Trip (Modul 3 & Modul 6: Hive CRUD).
class TripProvider extends ChangeNotifier {
  final TripRepository _repository;

  List<TripModel> _trips = [];
  bool _isLoading = false;
  String? _errorMessage;

  TripProvider({TripRepository? repository})
      : _repository = repository ?? TripRepository();

  List<TripModel> get trips => _trips;
  List<TripModel> get allTrips => _trips;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Memuat semua trip dari Hive database lokal (Read)
  Future<void> loadTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _trips = await _repository.getAllTrips();
    } catch (e) {
      _errorMessage = 'Gagal memuat data trip: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menambahkan trip baru ke Hive (Create)
  Future<bool> addTrip({
    required String tripName,
    required String destinationName,
    required String startDate,
    required double targetBudget,
    String notes = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newTrip = TripModel(
        id: DateTime.now().millisecondsSinceEpoch,
        tripName: tripName.trim(),
        destinationName: destinationName.trim(),
        startDate: startDate.trim(),
        targetBudget: targetBudget,
        notes: notes.trim(),
        status: 'Rencana',
        reminderEnabled: true,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _repository.addTrip(newTrip);
      await loadTrips();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambahkan trip: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui trip di Hive (Update)
  Future<bool> updateTrip(TripModel updatedTrip) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateTrip(updatedTrip);
      await loadTrips();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui trip: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Menghapus trip dari Hive (Delete)
  Future<bool> deleteTrip(int tripId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteTrip(tripId);
      await loadTrips();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus trip: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset session saat logout
  void clearSession() {
    _trips = [];
    notifyListeners();
  }
}
