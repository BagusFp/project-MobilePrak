/// Abstract base class yang mewakili entitas lokasi wisata (Konsep Abstraction & Inheritance OOP).
abstract class BasePlace {
  final int id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String address;

  const BasePlace({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  /// Method abstrak untuk mendapatkan ringkasan singkat destinasi (Polymorphism)
  String getSummary();
}

/// Model data destinasi wisata Merapi yang mewarisi BasePlace (Inheritance & Encapsulation OOP).
class DestinationModel extends BasePlace {
  final int categoryId;
  final String categoryName;
  final int elevationMdpl;
  final double ticketPrice;
  final String ticketPriceLabel;
  final String openingHours;
  final String estimatedDuration;
  final String temperatureRange;
  final String? imageUrl;
  final bool isSavedOffline;
  final double rating;
  final int reviewCount;
  final List<String> facilities;
  final double distanceKm;
  final String? bestVisitingTime;

  /// Generative Constructor dengan pemanggilan super (OOP Constructor & Super Keyword)
  const DestinationModel({
    required super.id,
    required super.name,
    required super.description,
    required super.latitude,
    required super.longitude,
    required super.address,
    required this.categoryId,
    required this.categoryName,
    required this.elevationMdpl,
    required this.ticketPrice,
    this.ticketPriceLabel = '',
    this.openingHours = '06.00 - 17.00 WIB',
    this.estimatedDuration = '45 - 60 Menit',
    this.temperatureRange = '18°C - 24°C',
    this.imageUrl,
    this.isSavedOffline = true,
    this.rating = 4.8,
    this.reviewCount = 500,
    this.facilities = const [],
    this.distanceKm = 0.0,
    this.bestVisitingTime = 'Pukul 05.30 - 08.00 WIB untuk langit jernih',
  });

  /// Implementasi method abstrak dari BasePlace (Polymorphism & Method Overriding)
  @override
  String getSummary() {
    return '$name ($categoryName) - Ketinggian: $elevationMdpl mdpl | Tiket: $formattedTicketPrice';
  }

  /// Getter terenkapsulasi untuk memformat harga tiket
  String get formattedTicketPrice {
    if (ticketPriceLabel.isNotEmpty) return ticketPriceLabel;
    if (ticketPrice <= 0) return 'Gratis / Donasi';
    return 'Rp ${ticketPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} / org';
  }

  /// Named Constructor untuk parsing data JSON dari HTTP Request API (Modul 5)
  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedFacilities = [];
    if (json['facilities'] is List) {
      parsedFacilities = (json['facilities'] as List).map((e) => e.toString()).toList();
    } else if (json['facilities'] is String && (json['facilities'] as String).isNotEmpty) {
      parsedFacilities = (json['facilities'] as String).split(',').map((e) => e.trim()).toList();
    }

    return DestinationModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Destinasi Merapi',
      description: json['description'] as String? ?? '',
      categoryId: json['category_id'] as int? ?? 1,
      categoryName: json['category_name'] as String? ?? 'Wisata Alam',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -7.5833,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 110.4422,
      elevationMdpl: json['elevation_mdpl'] as int? ?? 800,
      ticketPrice: (json['ticket_price'] as num?)?.toDouble() ?? 0.0,
      ticketPriceLabel: json['ticket_price_label'] as String? ?? '',
      openingHours: json['opening_hours'] as String? ?? '06.00 - 17.00 WIB',
      estimatedDuration: json['estimated_duration'] as String? ?? '45 - 60 Menit',
      temperatureRange: json['temperature_range'] as String? ?? '18°C - 24°C',
      address: json['address'] as String? ?? 'Kawasan Lereng Merapi, Sleman',
      imageUrl: json['image_url'] as String?,
      isSavedOffline: true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: json['review_count'] as int? ?? 100,
      facilities: parsedFacilities,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 4.2,
      bestVisitingTime: json['best_visiting_time'] as String?,
    );
  }

  /// Named Constructor dari Map lokal (SQLite / Cache / Mock)
  factory DestinationModel.fromMap(Map<String, dynamic> map) {
    return DestinationModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'latitude': latitude,
      'longitude': longitude,
      'elevation_mdpl': elevationMdpl,
      'ticket_price': ticketPrice,
      'ticket_price_label': ticketPriceLabel,
      'opening_hours': openingHours,
      'estimated_duration': estimatedDuration,
      'temperature_range': temperatureRange,
      'address': address,
      'image_url': imageUrl,
      'is_saved_offline': isSavedOffline ? 1 : 0,
      'rating': rating,
      'review_count': reviewCount,
      'facilities': facilities.join(', '),
      'distance_km': distanceKm,
      'best_visiting_time': bestVisitingTime,
    };
  }

  DestinationModel copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    String? categoryName,
    double? latitude,
    double? longitude,
    int? elevationMdpl,
    double? ticketPrice,
    String? ticketPriceLabel,
    String? openingHours,
    String? estimatedDuration,
    String? temperatureRange,
    String? address,
    String? imageUrl,
    bool? isSavedOffline,
    double? rating,
    int? reviewCount,
    List<String>? facilities,
    double? distanceKm,
    String? bestVisitingTime,
  }) {
    return DestinationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevationMdpl: elevationMdpl ?? this.elevationMdpl,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      ticketPriceLabel: ticketPriceLabel ?? this.ticketPriceLabel,
      openingHours: openingHours ?? this.openingHours,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      temperatureRange: temperatureRange ?? this.temperatureRange,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      isSavedOffline: isSavedOffline ?? this.isSavedOffline,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      facilities: facilities ?? this.facilities,
      distanceKm: distanceKm ?? this.distanceKm,
      bestVisitingTime: bestVisitingTime ?? this.bestVisitingTime,
    );
  }
}
