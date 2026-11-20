import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/trip_model.dart';

/// Service Local Database menggunakan Hive (Modul 6: Local Storage & NoSQL).
/// Dilengkapi sistem ketahanan (resilience) dan fallback memori agar operasi CRUD
/// tidak pernah gagal meskipun inisialisasi penyimpanan perangkat bermasalah.
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

  /// Mendapatkan box Hive secara aman dengan penanganan jika box belum terbuka
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
      debugPrint('TripLocalDb: Hive box belum terbuka atau path belum diset ($e)');
      return null;
    }
  }

  /// Inisialisasi awal Hive Box
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _isInitialized = true;
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      await instance.ensureSeeded();
    } catch (e) {
      debugPrint('TripLocalDb.init error: $e');
    }
  }

  List<TripModel> _getInitialSeededTrips() {
    return [
      TripModel(
        id: 101,
        tripName: 'Petualangan Sunrise Kaliadem',
        startDate: '25 Nov 2026',
        targetBudget: 350000.0,
        notes: 'Membawa jaket tebal, kamera, dan berangkat pukul 05.00 WIB.',
        status: 'Rencana',
        reminderEnabled: true,
        createdAt: '2026-11-20T09:00:00Z',
        destinations: const [
          TripDestinationItem(
            id: 1,
            name: 'Bunker Kaliadem',
            categoryName: 'Alam',
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAT5SWRj9svCiCBlgYQx-zjjhyIZQ5obyW29TwX8hzE5Kypnjt2XCT_aIxPg_VVv7WgrpGcCDqPyRVRXO4KbCMAz0DGV5uxOBVT1Xmb7iR5rzWOf_rSa3MzPiIhKT5twdqV6OFikGTSio858GCmZgcX2T__egyhyosgIhO3w5SnZZMjhWC2sbCeWnE8mHLxuV9z6LVj8ogmkLQSxHfEXY8KWYkJDjxiMoNk576yo3CyJTti8_Sacqg',
            latitude: -7.5833,
            longitude: 110.4422,
            elevationMdpl: 1165,
            ticketPrice: 10000.0,
            ticketPriceLabel: 'Rp 10.000 / orang',
            address: 'Dusun Kinahrejo, Cangkringan, Sleman',
            isVisited: true,
          ),
          TripDestinationItem(
            id: 3,
            name: 'Batu Alien (Batu Wajah)',
            categoryName: 'Alam',
            imageUrl: 'https://imgs.search.brave.com/vH955J-0x3vE_Bknp78xY-QzX28g1a0vL94c1g7r-5w/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9qdXJu/YWxwb3N0LmNvbS93/cC1jb250ZW50L3Vw/bG9hZHMvMjAyNC8x/MS9CYXR1LUFsaWVu/LmpwZw',
            latitude: -7.6025,
            longitude: 110.4502,
            elevationMdpl: 950,
            ticketPrice: 5000.0,
            ticketPriceLabel: 'Rp 5.000 / orang',
            address: 'Dusun Jambu, Kepuharjo, Cangkringan, Sleman',
            isVisited: false,
          ),
          TripDestinationItem(
            id: 2,
            name: 'Museum Sisa Hartaku',
            categoryName: 'Sejarah',
            imageUrl: 'https://imgs.search.brave.com/ai4F8_HazfFnn2G845KXNabBYKJ4ijhVWjYgGE9x33M/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9qdXJu/YWxwb3N0LmNvbS93/cC1jb250ZW50L3Vw/bG9hZHMvMjAyNC8x/MS9NaW5pLVNpc2Et/SGFydGFrdS53ZWJw',
            latitude: -7.6019,
            longitude: 110.4447,
            elevationMdpl: 920,
            ticketPrice: 0.0,
            ticketPriceLabel: 'Sukarela / donasi',
            address: 'Dusun Petung, Kepuharjo, Cangkringan, Sleman',
            isVisited: false,
          ),
        ],
      ),
      TripModel(
        id: 102,
        tripName: 'Wisata Edukasi & Memorial Merapi',
        startDate: '28 Nov 2026',
        targetBudget: 200000.0,
        notes: 'Kunjungan keluarga untuk mempelajari sejarah letusan Merapi.',
        status: 'Rencana',
        reminderEnabled: true,
        createdAt: '2026-11-20T09:00:00Z',
        destinations: const [
          TripDestinationItem(
            id: 9,
            name: 'Museum Gunungapi Merapi (MGM)',
            categoryName: 'Edukasi',
            imageUrl: 'https://imgs.search.brave.com/hVBIi_rN-Vx1KfEjPgREpv4SH0bhOpolHSHa92Fchak/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly90ZW1h/bmltdXdpc2F0YS5j/b20vd3AtY29udGVu/dC91cGxvYWRzLzIw/MjYvMDMvTXVzZXVt/LWd1bnVuZy1tZXJh/cGktNjAweDQ1MC5w/bmc',
            latitude: -7.6158,
            longitude: 110.4244,
            elevationMdpl: 780,
            ticketPrice: 10000.0,
            ticketPriceLabel: 'Rp 10.000 / orang',
            address: 'Jl. Kaliurang Km 22, Banteng, Hargobinangun, Pakem, Sleman',
            isVisited: false,
          ),
          TripDestinationItem(
            id: 4,
            name: 'Plunyon Kalikuning',
            categoryName: 'Alam',
            imageUrl: 'https://imgs.search.brave.com/hAoLHiE7BdJiNRTPUJ9IlHOekNCXuicizbIC-KeDp4M/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly93d3cu/c2h1dHRlcnN0b2Nr/LmNvbS9pbWFnZS1w/aG90by92aWV3LW1v/dW50LW1lcmFwaS1w/bHVueW9uLWthbGlr/dW5pbmctNjAwbnct/MTU4NDA0OTM5My5q/cGc',
            latitude: -7.5978,
            longitude: 110.4286,
            elevationMdpl: 1020,
            ticketPrice: 12000.0,
            ticketPriceLabel: 'Rp 12.000 / orang',
            address: 'Kedungsriti, Umbulharjo, Cangkringan, Sleman',
            isVisited: false,
          ),
        ],
      ),
    ];
  }

  /// Memastikan ada data awal trip jika database masih kosong
  Future<void> ensureSeeded() async {
    try {
      final box = await _getBox();
      if (box != null && box.isOpen) {
        if (box.isEmpty) {
          final initialTrips = _getInitialSeededTrips();
          for (var trip in initialTrips) {
            await box.put(trip.id, trip.toMap());
          }
          debugPrint('TripLocalDb: Data awal trip multi-destinasi berhasil di-seed ke Hive.');
        }
      }
    } catch (e) {
      debugPrint('TripLocalDb ensureSeeded error: $e');
    }
  }

  /// Read (Retrieve) seluruh data trip
  Future<List<TripModel>> getAllTrips() async {
    final List<TripModel> trips = [];
    try {
      final box = await _getBox();
      if (box != null && box.isOpen) {
        for (var key in box.keys) {
          try {
            final raw = box.get(key);
            if (raw != null && raw is Map) {
              trips.add(TripModel.fromMap(Map.from(raw)));
            }
          } catch (e) {
            debugPrint('Error parsing trip $key: $e');
          }
        }
      } else {
        // Fallback memori
        for (var map in _inMemoryFallback.values) {
          trips.add(TripModel.fromMap(map));
        }
      }
    } catch (e) {
      debugPrint('TripLocalDb getAllTrips error: $e');
    }

    // Jika masih kosong sama sekali, sediakan initial trips
    if (trips.isEmpty) {
      trips.addAll(_getInitialSeededTrips());
    }

    // Urutkan dari yang terbaru dibuat
    trips.sort((a, b) => b.id.compareTo(a.id));
    return trips;
  }

  /// Create data trip baru
  Future<void> addTrip(TripModel trip) async {
    _inMemoryFallback[trip.id] = trip.toMap();
    try {
      final box = await _getBox();
      if (box != null && box.isOpen) {
        await box.put(trip.id, trip.toMap());
      }
    } catch (e) {
      debugPrint('TripLocalDb addTrip error: $e');
    }
  }

  /// Update data trip yang sudah ada
  Future<void> updateTrip(TripModel trip) async {
    _inMemoryFallback[trip.id] = trip.toMap();
    try {
      final box = await _getBox();
      if (box != null && box.isOpen) {
        await box.put(trip.id, trip.toMap());
      }
    } catch (e) {
      debugPrint('TripLocalDb updateTrip error: $e');
    }
  }

  /// Delete data trip berdasarkan ID
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
