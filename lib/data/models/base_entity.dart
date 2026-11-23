/// Abstraksi entitas dasar untuk mendukung prinsip OOP (Modul 3 & OOP).
/// Menyediakan kontrak getter [id] dan metode serialisasi [toMap].
abstract class BaseEntity {
  int? get id;
  Map<String, dynamic> toMap();
}

