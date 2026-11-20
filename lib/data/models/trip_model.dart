/// Model Trip Perjalanan Wisata Merapi untuk Local Storage Hive (Modul 6 & OOP).
class TripModel {
  final int id;
  final String tripName;
  final String destinationName;
  final String startDate;
  final double targetBudget;
  final String notes;
  final String status; // 'Rencana', 'Selesai'
  final bool reminderEnabled;
  final String createdAt;

  const TripModel({
    required this.id,
    required this.tripName,
    required this.destinationName,
    required this.startDate,
    this.targetBudget = 250000.0,
    this.notes = '',
    this.status = 'Rencana',
    this.reminderEnabled = true,
    required this.createdAt,
  });

  /// Getter terenkapsulasi untuk memformat nominal target anggaran
  String get formattedBudget {
    return 'Rp ${targetBudget.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  bool get isCompleted => status.toLowerCase() == 'selesai';

  /// Named Constructor untuk deserialisasi dari Map/Hive Box (Modul 6)
  factory TripModel.fromMap(Map<dynamic, dynamic> map) {
    return TripModel(
      id: map['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      tripName: map['trip_name'] as String? ?? 'Trip Merapi',
      destinationName: map['destination_name'] as String? ?? 'Kawasan Kaliadem',
      startDate: map['start_date'] as String? ?? 'Segera',
      targetBudget: (map['target_budget'] as num?)?.toDouble() ?? 250000.0,
      notes: map['notes'] as String? ?? '',
      status: map['status'] as String? ?? 'Rencana',
      reminderEnabled: map['reminder_enabled'] as bool? ?? true,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Serialisasi ke Map untuk disimpan ke dalam Hive Box
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_name': tripName,
      'destination_name': destinationName,
      'start_date': startDate,
      'target_budget': targetBudget,
      'notes': notes,
      'status': status,
      'reminder_enabled': reminderEnabled,
      'created_at': createdAt,
    };
  }

  TripModel copyWith({
    int? id,
    String? tripName,
    String? destinationName,
    String? startDate,
    double? targetBudget,
    String? notes,
    String? status,
    bool? reminderEnabled,
    String? createdAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      tripName: tripName ?? this.tripName,
      destinationName: destinationName ?? this.destinationName,
      startDate: startDate ?? this.startDate,
      targetBudget: targetBudget ?? this.targetBudget,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
