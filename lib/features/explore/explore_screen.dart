import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_network_image.dart';
import '../../data/models/destination_model.dart';
import 'destination_detail_screen.dart';
import 'destination_provider.dart';

/// Layar Explore Destinasi Wisata Merapi (Modul 2, 3: State & Data, Modul 5: HTTP Request).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DestinationProvider>();
      if (provider.allDestinations.isEmpty) {
        provider.loadDestinations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destProvider = context.watch<DestinationProvider>();
    final destinations = destProvider.displayedDestinations;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Explore Wisata Merapi'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Segarkan Data dari API',
            onPressed: () => destProvider.loadDestinations(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Kolom Pencarian (Modul 2: TextField & Modul 3: TextEditingController)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => destProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Cari destinasi, bunker, museum...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          destProvider.clearSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withAlpha(80)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withAlpha(80)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Baris Kategori Filter (Modul 2: SingleChildScrollView Row)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
              itemCount: destProvider.categories.length,
              itemBuilder: (context, index) {
                final cat = destProvider.categories[index];
                final isSelected = destProvider.selectedCategory == cat.name;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.name),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: AppColors.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.outlineVariant.withAlpha(80),
                      ),
                    ),
                    onSelected: (_) => destProvider.setSelectedCategory(cat.name),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 3. Status Data (Loading, Error, atau ListView Dinamis - Modul 5)
          Expanded(
            child: _buildContent(destProvider, destinations),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DestinationProvider provider, List<DestinationModel> destinations) {
    // A. Loading State (Modul 5)
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Memuat data destinasi dari API...',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // B. Error State (Modul 5)
    if (provider.errorMessage != null && destinations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.loadDestinations(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // C. Empty State
    if (destinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: AppColors.outline),
            const SizedBox(height: 12),
            Text(
              'Tidak ada destinasi yang cocok.',
              style: AppTypography.titleMedium.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // D. Dynamic ListView (Modul 2 & Modul 5)
    return RefreshIndicator(
      onRefresh: () => provider.loadDestinations(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.margin,
          0,
          AppDimensions.margin,
          AppDimensions.spaceXl,
        ),
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          final dest = destinations[index];
          return _buildDestinationCard(context, dest);
        },
      ),
    );
  }

  Widget _buildDestinationCard(BuildContext context, DestinationModel dest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineVariant.withAlpha(80)),
      ),
      color: AppColors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Modul 4: Passing Data antarhalaman via Constructor
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DestinationDetailScreen(destination: dest),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Destinasi
            Stack(
              children: [
                AppNetworkImage(
                  imageUrl: dest.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                        const SizedBox(width: 4),
                        Text(
                          '${dest.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      dest.categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Konten Teks
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest.name,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dest.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.terrain_rounded, size: 14, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 4),
                          Text(
                            '${dest.elevationMdpl} mdpl',
                            style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                      Text(
                        dest.formattedTicketPrice,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
