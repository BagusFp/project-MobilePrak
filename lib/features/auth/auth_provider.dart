import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/database/preferences_helper.dart';
import '../../core/services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  final SupabaseService _supabaseService = SupabaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLocked = false;
  bool _isInitialized = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isBiometricSupported => false;
  bool get hasEnrolledBiometrics => false;
  bool get isBiometricEnabled => false;
  bool get isLocked => _isLocked;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isBiometricPromptActive => false;

  /// Inisialisasi awal saat aplikasi dibuka
  Future<void> init() async {
    try {
      final prefs = await PreferencesHelper.instance;

      final supabaseUser = _supabaseService.currentUser;
      final supabaseSession = _supabaseService.currentSession;

      // HANYA anggap user logged-in bila ada sesi Supabase aktif yang valid
      if (supabaseSession != null && supabaseUser != null) {
        final localUser = await _repository.getCurrentUser();
        // Cek avatar dari metadata atau tabel profiles Supabase
        String? remoteAvatar = supabaseUser.userMetadata?['avatar_url'] as String?;
        if (remoteAvatar == null || remoteAvatar.isEmpty) {
          final profile = await _supabaseService.getProfile(supabaseUser.id);
          remoteAvatar = profile?['avatar_url'] as String?;
        }
        final effectivePhoto = (remoteAvatar != null && remoteAvatar.isNotEmpty)
            ? remoteAvatar
            : (localUser?.profilePhoto ?? prefs.getUserPhoto());

        if (remoteAvatar != null && remoteAvatar.isNotEmpty && remoteAvatar != prefs.getUserPhoto()) {
          await prefs.setUserPhoto(remoteAvatar);
        }

        final baseUser = localUser ?? UserModel(
          id: prefs.getUserId() ?? 1,
          supabaseId: supabaseUser.id,
          name: supabaseUser.userMetadata?['name'] ?? prefs.getUserName() ?? 'Wisatawan Merapi',
          email: supabaseUser.email ?? prefs.getUserEmail() ?? '',
          profilePhoto: effectivePhoto,
          passwordHash: '',
          createdAt: supabaseUser.createdAt,
        );
        _currentUser = baseUser.copyWith(profilePhoto: effectivePhoto);
      } else {
        // Jangan izinkan bypass tanpa sesi Supabase yang valid
        _currentUser = null;
        await prefs.clearSession();
      }
    } catch (e) {
      debugPrint('Error init AuthProvider: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> refreshBiometricStatus() async {}

  /// Login email & password via Supabase
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _repository.login(email: email, password: password);
    _setLoading(false);

    if (result.isSuccess) {
      _currentUser = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  /// Registrasi akun baru
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _repository.register(
      name: name,
      email: email,
      password: password,
    );
    _setLoading(false);

    if (result.isSuccess) {
      _currentUser = result.user;
      _isLocked = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithBiometrics() async => false;

  Future<bool> unlockWithBiometrics() async => true;

  Future<AuthResult> verifyAccountPassword(String password) async {
    if (_currentUser == null) {
      return const AuthResult(
        isSuccess: false,
        message: 'Tidak ada sesi pengguna aktif.',
      );
    }

    _setLoading(true);
    _errorMessage = null;

    final result = await _repository.verifyAccountPassword(
      email: _currentUser!.email,
      password: password,
    );

    _setLoading(false);

    if (result.isSuccess) {
      _errorMessage = null;
      notifyListeners();
      return result;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return result;
    }
  }

  void lockApp() {}

  Future<bool> setBiometricEnabled(bool enabled) async => false;

  Future<void> toggleBiometric(bool enabled) async {}

  /// Logout dari sesi
  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    _isLocked = false;
    notifyListeners();
  }

  /// Memperbarui nama dan/atau foto profil pengguna
  Future<bool> updateProfile({String? name, String? profilePhoto}) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    _errorMessage = null;

    final userId = _currentUser!.id ?? 1;
    final res = await _repository.updateProfile(
      userId: userId,
      name: name,
      profilePhoto: profilePhoto,
    );
    _setLoading(false);

    if (res.isSuccess) {
      if (res.user != null) {
        _currentUser = res.user;
      } else {
        _currentUser = _currentUser!.copyWith(
          name: name,
          profilePhoto: profilePhoto,
        );
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// Upload foto avatar ke Supabase Storage (atau null jika offline/gagal)
  Future<String?> uploadAvatarBytes(Uint8List bytes, [String fileExt = 'webp']) async {
    final userId = _currentUser?.supabaseId ??
        _supabaseService.currentUser?.id ??
        (_currentUser?.id != null ? 'user_${_currentUser!.id}' : 'user_1');
    final url = await _supabaseService.uploadAvatar(
      userId: userId,
      bytes: bytes,
      fileExt: fileExt,
    );
    if (url == null) {
      _errorMessage = _supabaseService.lastAvatarUploadError ?? 'Gagal mengunggah foto ke Supabase Storage.';
      notifyListeners();
    }
    return url;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @visibleForTesting
  void setUserForTesting(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  @visibleForTesting
  void setLockedForTesting(bool locked) {
    _isLocked = locked;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
