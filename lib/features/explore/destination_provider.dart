import 'package:flutter/foundation.dart';
import '../../data/models/category_model.dart';
import '../../data/models/destination_model.dart';
import '../../data/repositories/destination_repository.dart';

/// Provider untuk manajemen state Destinasi & Explore (Modul 3 & Modul 5).
class DestinationProvider extends ChangeNotifier {
  final DestinationRepository _repository;

  List<DestinationModel> _allDestinations = [];
  List<DestinationModel> _displayedDestinations = [];
  List<CategoryModel> _categories = [];
  final Set<int> _favoriteIds = {};

  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _isLoading = false;
  String? _errorMessage;

  DestinationProvider({DestinationRepository? repository})
      : _repository = repository ?? DestinationRepository() {
    _categories = _repository.getCategories();
  }

  // Getters
  List<DestinationModel> get allDestinations => _allDestinations;
  List<DestinationModel> get displayedDestinations => _displayedDestinations;
  List<CategoryModel> get categories => _categories;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Memuat daftar destinasi dari API via HTTP GET (Modul 5: Fetch, Parse, Render)
  Future<void> loadDestinations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allDestinations = await _repository.getAllDestinations();
      _applyFilter();
    } catch (e) {
      _errorMessage = 'Gagal memuat destinasi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update pencarian kata kunci
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  /// Bersihkan kolom pencarian
  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }

  /// Pilih filter kategori
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  /// Toggle status favorit
  void toggleFavorite(int id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  bool isFavorite(int id) => _favoriteIds.contains(id);

  /// Menerapkan filter pencarian dan kategori (Conditional logic)
  void _applyFilter() {
    _displayedDestinations = _allDestinations.where((dest) {
      final matchesQuery = _searchQuery.isEmpty ||
          dest.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          dest.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          dest.address.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'Semua' ||
          dest.categoryName.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesQuery && matchesCategory;
    }).toList();
  }
}
