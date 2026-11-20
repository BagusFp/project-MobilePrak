import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../features/notification/notification_model.dart';

/// Helper terpusat untuk mengelola Shared Preferences (Modul 6: Local Storage & Session).
class PreferencesHelper {
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhoto = 'user_photo';
  static const String _keyIsLoggedIn = 'is_logged_in';

  static PreferencesHelper? _instance;
  static SharedPreferences? _preferences;

  PreferencesHelper._internal();

  static Future<PreferencesHelper> get instance async {
    _instance ??= PreferencesHelper._internal();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Menyimpan sesi login pengguna (Modul 6)
  Future<void> saveUserSession({
    required int userId,
    required String email,
    required String name,
    String? photo,
  }) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserName, name);
    if (photo != null && photo.isNotEmpty) {
      await prefs.setString(_keyUserPhoto, photo);
    }
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Menghapus sesi pengguna saat logout
  Future<void> clearSession() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserPhoto);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  bool isLoggedIn() {
    return _preferences?.getBool(_keyIsLoggedIn) ?? false;
  }

  int? getUserId() {
    return _preferences?.getInt(_keyUserId);
  }

  String? getUserEmail() {
    return _preferences?.getString(_keyUserEmail);
  }

  String? getUserName() {
    return _preferences?.getString(_keyUserName);
  }

  Future<void> setUserName(String name) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  String? getUserPhoto() {
    return _preferences?.getString(_keyUserPhoto);
  }

  Future<void> setUserPhoto(String? photo) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    if (photo == null || photo.isEmpty) {
      await prefs.remove(_keyUserPhoto);
    } else {
      await prefs.setString(_keyUserPhoto, photo);
    }
  }

  static const String _keySentNotifications = 'sent_notifications_json';

  Future<void> saveSentNotifications(List<NotificationModel> notifications) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final jsonList = notifications.map((n) => jsonEncode(n.toMap())).toList();
    await prefs.setStringList(_keySentNotifications, jsonList);
  }

  List<NotificationModel> getSentNotifications() {
    final list = _preferences?.getStringList(_keySentNotifications);
    if (list == null) return [];
    try {
      return list
          .map((s) => NotificationModel.fromMap(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addSentNotification(NotificationModel item) async {
    final existing = getSentNotifications();
    existing.removeWhere((n) => n.id == item.id && n.title == item.title);
    existing.insert(0, item);
    await saveSentNotifications(existing);
  }

  UserModel? getCurrentUser() {
    final loggedIn = isLoggedIn();
    if (!loggedIn) return null;
    return UserModel(
      id: getUserId() ?? 1,
      name: getUserName() ?? 'Wisatawan Merapi',
      email: getUserEmail() ?? 'wisatawan@meratrip.id',
      profilePhoto: getUserPhoto(),
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}
