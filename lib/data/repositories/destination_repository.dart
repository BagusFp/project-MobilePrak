import '../../core/services/api_service.dart';
import '../mock/mock_destinations.dart';
import '../models/category_model.dart';
import '../models/destination_model.dart';

/// Repository untuk data destinasi wisata Merapi (Modul 5 & OOP).
class DestinationRepository {
  /// Mengambil daftar kategori destinasi
  List<CategoryModel> getCategories() {
    return MockDestinations.categories;
  }

  /// Mengambil seluruh destinasi melalui ApiService (HTTP Request)
  Future<List<DestinationModel>> getAllDestinations() async {
    return await ApiService.fetchDestinations();
  }

  /// Mengambil detail destinasi berdasarkan ID
  Future<DestinationModel?> getDestinationById(int id) async {
    final all = await getAllDestinations();
    try {
      return all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Pencarian dan pemfilteran destinasi berdasarkan query dan kategori
  Future<List<DestinationModel>> searchAndFilterDestinations({
    String query = '',
    String categoryName = 'Semua',
  }) async {
    final all = await getAllDestinations();

    return all.where((dest) {
      final matchQuery = query.isEmpty ||
          dest.name.toLowerCase().contains(query.toLowerCase()) ||
          dest.address.toLowerCase().contains(query.toLowerCase()) ||
          dest.categoryName.toLowerCase().contains(query.toLowerCase()) ||
          dest.description.toLowerCase().contains(query.toLowerCase());

      final matchCategory = categoryName == 'Semua' ||
          dest.categoryName.toLowerCase() == categoryName.toLowerCase();

      return matchQuery && matchCategory;
    }).toList();
  }
}
