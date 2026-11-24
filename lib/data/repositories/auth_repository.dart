import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../core/database/preferences_helper.dart';
import '../../core/services/supabase_service.dart';

class AuthResult {
  final bool isSuccess;
  final String message;
  final UserModel? user;

  const AuthResult({
    required this.isSuccess,
    required this.message,
    this.user,
  });
}

class AuthRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Pendaftaran akun baru langsung ke Supabase Auth & simpan sesi ke Preferences
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    try {
      final supabaseRes = await _supabaseService.signUp(
        email: cleanEmail,
        password: password,
        name: cleanName,
      );
      final supabaseUserId = supabaseRes.user?.id;
      debugPrint('Supabase Auth register sukses: User ID = $supabaseUserId');

      final newUser = UserModel(
        id: 1,
        supabaseId: supabaseUserId,
        name: cleanName,
        email: cleanEmail,
        passwordHash: '',
        isBiometricEnabled: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Simpan sesi aktif ke Preferences (Modul 6)
      final prefs = await PreferencesHelper.instance;
      await prefs.saveUserSession(
        userId: 1,
        supabaseId: supabaseUserId,
        email: cleanEmail,
        name: cleanName,
        token: supabaseRes.session?.accessToken ?? 'session_active',
      );

      return AuthResult(
        isSuccess: true,
        message: 'Registrasi berhasil! Akun Anda telah terdaftar di Supabase.',
        user: newUser,
      );
    } on AuthException catch (e) {
      debugPrint('Supabase AuthException register: ${e.message}');
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('user already exists')) {
        return const AuthResult(
          isSuccess: false,
          message: 'Email sudah terdaftar di Supabase. Silakan langsung masuk.',
        );
      }
      if (e.message.toLowerCase().contains('invalid') && e.message.toLowerCase().contains('email')) {
        return const AuthResult(
          isSuccess: false,
          message: 'Format email tidak diterima oleh Supabase. Gunakan email valid (misal @gmail.com).',
        );
      }
      return AuthResult(
        isSuccess: false,
        message: 'Gagal mendaftar di Supabase: ${e.message}',
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Gagal melakukan pendaftaran: $e',
      );
    }
  }

  /// Login langsung ke Supabase Cloud Authentication & simpan sesi ke Preferences
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      final supabaseRes = await _supabaseService.signIn(
        email: cleanEmail,
        password: password,
      );
      final supabaseUser = supabaseRes.user;
      if (supabaseUser == null) {
        return const AuthResult(
          isSuccess: false,
          message: 'Autentikasi Supabase gagal. Silakan coba lagi.',
        );
      }

      final supabaseUserId = supabaseUser.id;
      final userName = (supabaseUser.userMetadata?['name'] as String?)?.trim() ?? 'Wisatawan Merapi';
      final userPhoto = supabaseUser.userMetadata?['avatar_url'] as String?;
      debugPrint('Supabase Auth login sukses: User ID = $supabaseUserId ($userName)');

      final user = UserModel(
        id: 1,
        supabaseId: supabaseUserId,
        name: userName,
        email: cleanEmail,
        profilePhoto: userPhoto,
        passwordHash: '',
        isBiometricEnabled: false,
        createdAt: supabaseUser.createdAt,
      );

      // Simpan sesi aktif ke Preferences (Modul 6)
      final prefs = await PreferencesHelper.instance;
      await prefs.saveUserSession(
        userId: 1,
        supabaseId: supabaseUserId,
        email: cleanEmail,
        name: user.name,
        token: supabaseRes.session?.accessToken ?? 'session_active',
      );
      if (userPhoto != null && userPhoto.isNotEmpty) {
        await prefs.setUserPhoto(userPhoto);
      }

      return AuthResult(
        isSuccess: true,
        message: 'Berhasil masuk ke MeraTrip!',
        user: user,
      );
    } on AuthException catch (e) {
      debugPrint('Supabase AuthException login: ${e.message}');
      if (e.message.toLowerCase().contains('email not confirmed')) {
        return const AuthResult(
          isSuccess: false,
          message: 'Email belum dikonfirmasi di Supabase. Silakan periksa inbox email Anda, atau matikan "Confirm email" di Dashboard Supabase (Authentication -> Email).',
        );
      }
      if (e.message.toLowerCase().contains('invalid login credentials') ||
          e.message.toLowerCase().contains('invalid credentials')) {
        return const AuthResult(
          isSuccess: false,
          message: 'Email atau kata sandi tidak sesuai. Silakan periksa kembali.',
        );
      }
      return AuthResult(
        isSuccess: false,
        message: 'Supabase Auth: ${e.message}',
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Terjadi kesalahan saat masuk: $e',
      );
    }
  }

  /// Autentikasi biometrik OS
  Future<AuthResult> loginWithBiometrics() async {
    return const AuthResult(
      isSuccess: false,
      message: 'Fitur biometrik tidak diaktifkan.',
    );
  }

  /// Memperoleh data profil user saat ini dari SharedPreferences & Supabase
  Future<UserModel?> getCurrentUser() async {
    final prefs = await PreferencesHelper.instance;
    final email = prefs.getUserEmail();
    if (email == null || email.isEmpty) return null;

    final supabaseUser = _supabaseService.currentUser;
    final name = prefs.getUserName() ?? (supabaseUser?.userMetadata?['name'] as String?) ?? 'Wisatawan Merapi';
    final photo = prefs.getUserPhoto() ?? (supabaseUser?.userMetadata?['avatar_url'] as String?);

    return UserModel(
      id: prefs.getUserId() ?? 1,
      supabaseId: prefs.getSupabaseId() ?? supabaseUser?.id,
      name: name,
      email: email,
      profilePhoto: photo,
      passwordHash: '',
      isBiometricEnabled: prefs.isBiometricEnabled(),
      createdAt: supabaseUser?.createdAt ?? DateTime.now().toIso8601String(),
    );
  }

  /// Memperbarui nama dan/atau foto profil pengguna ke Supabase & Preferences
  Future<AuthResult> updateProfile({
    required int userId,
    String? name,
    String? profilePhoto,
  }) async {
    try {
      final prefs = await PreferencesHelper.instance;
      if (name != null && name.trim().isNotEmpty) {
        await prefs.setUserName(name.trim());
      }
      if (profilePhoto != null) {
        await prefs.setUserPhoto(profilePhoto);
      }

      // Update di Supabase bila ada sesi aktif
      final supabaseUser = _supabaseService.currentUser;
      if (supabaseUser != null) {
        try {
          await _supabaseService.client.auth.updateUser(
            UserAttributes(
              data: {
                if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
                if (profilePhoto != null && profilePhoto.isNotEmpty) 'avatar_url': profilePhoto,
              },
            ),
          );
        } catch (e) {
          debugPrint('Supabase updateUser metadata error: $e');
        }

        try {
          await _supabaseService.upsertProfile({
            'id': supabaseUser.id,
            'email': supabaseUser.email,
            if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
            if (profilePhoto != null && profilePhoto.isNotEmpty) 'avatar_url': profilePhoto,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Supabase upsertProfile error: $e');
        }
      }

      final updatedUser = await getCurrentUser();
      return AuthResult(
        isSuccess: true,
        message: 'Profil berhasil diperbarui.',
        user: updatedUser,
      );
    } catch (e) {
      debugPrint('AuthRepository updateProfile error: $e');
      return AuthResult(
        isSuccess: false,
        message: 'Gagal memperbarui profil: $e',
      );
    }
  }

  /// Verifikasi kata sandi akun langsung via Supabase
  Future<AuthResult> verifyAccountPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.isEmpty) {
      return const AuthResult(
        isSuccess: false,
        message: 'Email atau kata sandi tidak boleh kosong.',
      );
    }

    try {
      final res = await _supabaseService.signIn(
        email: cleanEmail,
        password: password,
      );

      final user = res.user;
      final session = res.session;

      if (user == null || session == null) {
        return const AuthResult(
          isSuccess: false,
          message: 'Gagal memverifikasi kata sandi. Silakan coba lagi.',
        );
      }

      final prefs = await PreferencesHelper.instance;
      final userId = prefs.getUserId() ?? 1;
      await prefs.saveUserSession(
        userId: userId,
        supabaseId: user.id,
        email: cleanEmail,
        name: user.userMetadata?['name'] ?? prefs.getUserName() ?? 'Wisatawan Merapi',
        token: session.accessToken,
      );

      final currentUser = await getCurrentUser();
      return AuthResult(
        isSuccess: true,
        message: 'Kata sandi akun berhasil diverifikasi.',
        user: currentUser ?? UserModel(
          id: userId,
          supabaseId: user.id,
          name: user.userMetadata?['name'] ?? 'Wisatawan Merapi',
          email: cleanEmail,
          passwordHash: '',
          isBiometricEnabled: prefs.isBiometricEnabled(),
          createdAt: user.createdAt,
        ),
      );
    } on AuthException catch (e) {
      debugPrint('Supabase verifyAccountPassword AuthException: ${e.message}');
      if (e.message.toLowerCase().contains('invalid login credentials') ||
          e.message.toLowerCase().contains('invalid credentials')) {
        return const AuthResult(
          isSuccess: false,
          message: 'Kata sandi akun tidak sesuai. Silakan periksa kembali.',
        );
      }
      return AuthResult(
        isSuccess: false,
        message: 'Verifikasi gagal: ${e.message}',
      );
    } catch (e) {
      debugPrint('Supabase verifyAccountPassword network/server error: $e');
      return const AuthResult(
        isSuccess: false,
        message: 'Tidak dapat menghubungi server Supabase. Pastikan koneksi internet aktif.',
      );
    }
  }

  /// Mengubah status biometrik user
  Future<bool> setBiometricEnabled(int userId, bool enabled) async {
    return false;
  }

  /// Logout dan hapus sesi di lokal dan Supabase
  Future<void> logout() async {
    final prefs = await PreferencesHelper.instance;
    await prefs.clearSession();
    try {
      await _supabaseService.signOut();
    } catch (_) {}
  }
}
