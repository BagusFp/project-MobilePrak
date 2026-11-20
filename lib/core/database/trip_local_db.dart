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
          startDate: '25 Nov 2026',
          targetBudget: 350000.0,
          notes: 'Membawa jaket tebal, kamera, dan berangkat pukul 05.00 WIB.',
          status: 'Rencana',
          reminderEnabled: true,
          createdAt: DateTime.now().toIso8601String(),
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
          createdAt: DateTime.now().toIso8601String(),
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
            ),
          ],
        ),
      ];

      for (var trip in initialTrips) {
        await _box.put(trip.id, trip.toMap());
      }
      debugPrint('TripLocalDb: Data awal trip multi-destinasi berhasil di-seed ke Hive.');
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
