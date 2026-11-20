import 'destination_model.dart';

/// Item destinasi di dalam suatu rencana perjalanan (Satu Trip Banyak Destinasi).
class TripDestinationItem {
  final int id;
  final String name;
  final String categoryName;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final int elevationMdpl;
  final double ticketPrice;
  final String ticketPriceLabel;
  final String address;

  const TripDestinationItem({
    required this.id,
    required this.name,
    this.categoryName = 'Wisata Alam',
    this.imageUrl,
    this.latitude = -7.5833,
    this.longitude = 110.4422,
    this.elevationMdpl = 800,
    this.ticketPrice = 0.0,
    this.ticketPriceLabel = '',
    this.address = 'Kawasan Merapi, Sleman',
  });

  /// Getter alias untuk kategori (OOP Encapsulation)
  String get category => categoryName;

  /// Factory untuk membuat item destinasi dari DestinationModel (OOP)
  factory TripDestinationItem.fromDestination(DestinationModel dest) {
    return TripDestinationItem(
      id: dest.id,
      name: dest.name,
      categoryName: dest.categoryName,
      imageUrl: dest.imageUrl,
      latitude: dest.latitude,
      longitude: dest.longitude,
      elevationMdpl: dest.elevationMdpl,
      ticketPrice: dest.ticketPrice,
      ticketPriceLabel: dest.formattedTicketPrice,
      address: dest.address,
    );
  }

  /// Deserialisasi dari Map (Hive Local Storage)
  factory TripDestinationItem.fromMap(Map<dynamic, dynamic> map) {
    return TripDestinationItem(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Destinasi Merapi',
      categoryName: map['category_name'] as String? ?? 'Wisata Alam',
      imageUrl: map['image_url'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? -7.5833,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 110.4422,
      elevationMdpl: map['elevation_mdpl'] as int? ?? 800,
      ticketPrice: (map['ticket_price'] as num?)?.toDouble() ?? 0.0,
      ticketPriceLabel: map['ticket_price_label'] as String? ?? '',
      address: map['address'] as String? ?? 'Kawasan Merapi, Sleman',
    );
  }

  /// Konversi kembali ke DestinationModel untuk navigasi ke detail
  DestinationModel toDestinationModel() {
    return DestinationModel(
      id: id,
      name: name,
      description: 'Destinasi wisata terpilih di lereng Merapi.',
      categoryId: 1,
      categoryName: categoryName,
      latitude: latitude,
      longitude: longitude,
      elevationMdpl: elevationMdpl,
      ticketPrice: ticketPrice,
      ticketPriceLabel: ticketPriceLabel,
      address: address,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_name': categoryName,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'elevation_mdpl': elevationMdpl,
      'ticket_price': ticketPrice,
      'ticket_price_label': ticketPriceLabel,
      'address': address,
    };
  }
}

/// Model Trip Perjalanan Wisata Merapi untuk Local Storage Hive (Modul 6 & OOP).
/// Satu Trip memiliki relasi 1-to-N dengan banyak destinasi wisata.
class TripModel {
  final int id;
  final String tripName;
  final String startDate;
  final double targetBudget;
  final String notes;
  final String status; // 'Rencana', 'Selesai'
  final bool reminderEnabled;
  final String createdAt;
  final List<TripDestinationItem> destinations;

  TripModel({
    required this.id,
    required this.tripName,
    required this.startDate,
    this.targetBudget = 250000.0,
    this.notes = '',
    this.status = 'Rencana',
    this.reminderEnabled = true,
    this.createdAt = '',
    List<TripDestinationItem>? destinations,
    String? destinationName,
  }) : destinations = destinations ??
            (destinationName != null && destinationName.isNotEmpty
                ? [
                    TripDestinationItem(
                      id: 0,
                      name: destinationName,
                    )
                  ]
                : const []);

  /// Getter terenkapsulasi untuk memformat nominal target anggaran
  String get formattedBudget {
    return 'Rp ${targetBudget.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  bool get isCompleted => status.toLowerCase() == 'selesai';

  int get totalDestinations => destinations.length;

  /// Nama destinasi ringkas (untuk kompatibilitas tampilan kartu lama)
  String get destinationName {
    if (destinations.isEmpty) return 'Belum ada destinasi dipilih';
    if (destinations.length == 1) return destinations.first.name;
    return '${destinations.first.name} (+${destinations.length - 1} destinasi lainnya)';
  }

  /// Ringkasan seluruh destinasi yang dipisahkan tanda koma
  String get destinationsSummary {
    if (destinations.isEmpty) return 'Belum ada destinasi';
    return destinations.map((d) => d.name).join(', ');
  }

  /// Named Constructor untuk deserialisasi dari Map/Hive Box (Modul 6)
  /// Menyediakan migrasi & backward-compatibility penuh untuk data lama.
  factory TripModel.fromMap(Map<dynamic, dynamic> map) {
    List<TripDestinationItem> parsedDestinations = [];

    if (map['destinations'] is List) {
      parsedDestinations = (map['destinations'] as List)
          .map((item) => TripDestinationItem.fromMap(item as Map<dynamic, dynamic>))
          .toList();
    } else if (map['destination_name'] is String && (map['destination_name'] as String).isNotEmpty) {
      // Mekanisme kompatibilitas: konversi data format lama ke list destinasi
      final oldDestName = map['destination_name'] as String;
      parsedDestinations = [
        TripDestinationItem(
          id: 1,
          name: oldDestName,
          categoryName: 'Wisata Alam',
          latitude: -7.5833,
          longitude: 110.4422,
        ),
      ];
    }

    return TripModel(
      id: map['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      tripName: map['trip_name'] as String? ?? 'Trip Merapi',
      startDate: map['start_date'] as String? ?? 'Segera',
      targetBudget: (map['target_budget'] as num?)?.toDouble() ?? 250000.0,
      notes: map['notes'] as String? ?? '',
      status: map['status'] as String? ?? 'Rencana',
      reminderEnabled: map['reminder_enabled'] as bool? ?? true,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      destinations: parsedDestinations,
    );
  }

  /// Serialisasi ke Map untuk disimpan ke dalam Hive Box
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_name': tripName,
      'destination_name': destinations.isNotEmpty ? destinations.first.name : '',
      'start_date': startDate,
      'target_budget': targetBudget,
      'notes': notes,
      'status': status,
      'reminder_enabled': reminderEnabled,
      'created_at': createdAt,
      'destinations': destinations.map((d) => d.toMap()).toList(),
    };
  }

  TripModel copyWith({
    int? id,
    String? tripName,
    String? startDate,
    double? targetBudget,
    String? notes,
    String? status,
    bool? reminderEnabled,
    String? createdAt,
    List<TripDestinationItem>? destinations,
  }) {
    return TripModel(
      id: id ?? this.id,
      tripName: tripName ?? this.tripName,
      startDate: startDate ?? this.startDate,
      targetBudget: targetBudget ?? this.targetBudget,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      destinations: destinations ?? this.destinations,
    );
  }
}
