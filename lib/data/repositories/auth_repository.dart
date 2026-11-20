import '../../core/database/preferences_helper.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserModel? user;

  AuthResult.success(this.user)
      : isSuccess = true,
        errorMessage = null;

  AuthResult.failure(this.errorMessage)
      : isSuccess = false,
        user = null;
}

/// Repository untuk autentikasi pengguna dengan SharedPreferences (Modul 6 & OOP).
class AuthRepository {
  final PreferencesHelper? prefsHelper;

  AuthRepository({this.prefsHelper});

  Future<PreferencesHelper> get _prefs async =>
      prefsHelper ?? await PreferencesHelper.instance;

  /// Memeriksa status login yang tersimpan
  Future<UserModel?> getCurrentUser() async {
    final prefs = await _prefs;
    return prefs.getCurrentUser();
  }

  /// Login sederhana menggunakan SharedPreferences
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return AuthResult.failure('Email dan kata sandi tidak boleh kosong.');
    }

    final prefs = await _prefs;
    final displayName = email.split('@').first;
    final capitalizedName = displayName.isNotEmpty
        ? displayName[0].toUpperCase() + displayName.substring(1)
        : 'Wisatawan';

    final user = UserModel(
      id: 1,
      name: prefs.getUserName() ?? capitalizedName,
      email: email,
      profilePhoto: prefs.getUserPhoto(),
      createdAt: DateTime.now().toIso8601String(),
    );

    await prefs.saveUserSession(
      userId: user.id,
      email: user.email,
      name: user.name,
      photo: user.profilePhoto,
    );

    return AuthResult.success(user);
  }

  /// Pendaftaran pengguna baru
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return AuthResult.failure('Lengkapi semua data pendaftaran.');
    }

    final prefs = await _prefs;
    final user = UserModel(
      id: 1,
      name: name,
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );

    await prefs.saveUserSession(
      userId: user.id,
      email: user.email,
      name: user.name,
    );

    return AuthResult.success(user);
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.clearSession();
  }
}
