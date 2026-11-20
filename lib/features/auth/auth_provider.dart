import 'package:flutter/foundation.dart';
import '../../core/database/preferences_helper.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Provider untuk autentikasi dan sesi pengguna (Modul 3 & Modul 6).
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  /// Inisialisasi awal saat aplikasi dibuka
  Future<void> init() async {
    try {
      _currentUser = await _repository.getCurrentUser();
    } catch (e) {
      debugPrint('AuthProvider init error: $e');
      _currentUser = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Login akun wisatawan
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.login(email: email, password: password);
    _isLoading = false;

    if (result.isSuccess) {
      _currentUser = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Pendaftaran akun baru
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.register(
      name: name,
      email: email,
      password: password,
    );
    _isLoading = false;

    if (result.isSuccess) {
      _currentUser = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui nama profil pengguna (Disimpan ke SharedPreferences)
  Future<void> updateUserName(String newName) async {
    if (newName.trim().isEmpty) return;
    final prefs = await PreferencesHelper.instance;
    await prefs.setUserName(newName.trim());

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(name: newName.trim());
      notifyListeners();
    }
  }

  /// Logout akun pengguna
  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    notifyListeners();
  }
}
