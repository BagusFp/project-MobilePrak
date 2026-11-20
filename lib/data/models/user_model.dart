/// Model data pengguna untuk autentikasi dan profil (Modul 3, 6, & OOP).
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? profilePhoto;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
    required this.createdAt,
  });

  /// Named constructor default untuk wisatawan demo
  factory UserModel.defaultUser() {
    return UserModel(
      id: 1,
      name: 'Bima Sakti',
      email: 'bima.sakti@wisatawan.id',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  /// Named constructor dari SharedPreferences Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? 'Wisatawan Merapi',
      email: map['email'] as String? ?? '',
      profilePhoto: map['profile_photo'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_photo': profilePhoto,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? profilePhoto,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
