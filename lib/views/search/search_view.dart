// lib/views/search/search_view.dart
// Layar Antarmuka Pencarian Universal & Filter Multi-Kriteria (SRC — PB 11 / PB-051 s.d. PB-055)

import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import '../../controllers/search_controller.dart';
import '../../models/movie_model.dart';
import '../../models/cinema_model.dart';
import '../../models/fnb_item_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/currency_helper.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppSearchController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildSearchBar(context, controller),
      body: Column(
        children: [
          // ── Tab Kategori Entitas (Semua, Film, Bioskop, F&B) ──────────────
          _buildEntityChips(controller),

          // ── Bar Filter Aktif (Jika Ada) ───────────────────────────────────
          _buildActiveFilterBar(controller),

          // ── Konten Utama (History, Skeleton, Hasil, Empty State) ──────────
          Expanded(
            child: Obx(() {
              if (controller.isInitialLoading.value ||
                  controller.isLoading.value) {
                return _buildSkeletonLoading();
              }

              // Jika input kosong & tidak ada filter aktif: tampilkan riwayat (PB-054)
              if (controller.searchQuery.value.trim().isEmpty &&
                  !controller.hasActiveFilters) {
                return _buildSearchHistorySection(controller);
              }

              // Jika tidak ada hasil pencarian (PB-055)
              if (controller.isEmptyResult) {
                return _buildEmptyState(controller);
              }

              // Tampilkan daftar hasil pencarian multi-entitas (PB-051, PB-052, PB-053)
              return _buildSearchResults(controller);
            }),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. APP BAR & SEARCH INPUT BAR (PB-051)
  // =========================================================================

  PreferredSizeWidget _buildSearchBar(
      BuildContext context, AppSearchController controller) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => Get.back(),
      ),
      title: Container(
        height: 44,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: TextField(
          controller: controller.searchInput,
          onChanged: controller.onQueryChanged,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Cari film, bioskop, atau menu F&B...',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 20),
            suffixIcon: Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: controller.clearSearch,
                );
              }
              return const SizedBox.shrink();
            }),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
      actions: [
        // Tombol Filter Modal dengan Badge Counter (PB-052)
        Obx(() {
          final count = controller.activeFilterCount;
          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
                tooltip: 'Filter Pencarian',
                onPressed: () => _showFilterBottomSheet(context, controller),
              ),
              if (count > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
        const SizedBox(width: 4),
      ],
    );
  }

  // =========================================================================
  // 2. ENTITY CHIPS FILTER (Semua, Film, Bioskop, F&B)
  // =========================================================================

  Widget _buildEntityChips(AppSearchController controller) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() {
        final current = controller.selectedEntity.value;

        return Row(
          children: [
            _buildTabChip(
              label: 'Semua',
              icon: Icons.grid_view_rounded,
              isSelected: current == SearchEntityType.all,
              count: controller.totalResultCount,
              onTap: () => controller.setEntity(SearchEntityType.all),
            ),
            const SizedBox(width: 8),
            _buildTabChip(
              label: 'Film',
              icon: Icons.movie_rounded,
              isSelected: current == SearchEntityType.movie,
              count: controller.filteredMovies.length,
              onTap: () => controller.setEntity(SearchEntityType.movie),
            ),
            const SizedBox(width: 8),
            _buildTabChip(
              label: 'Bioskop',
              icon: Icons.location_on_rounded,
              isSelected: current == SearchEntityType.cinema,
              count: controller.filteredCinemas.length,
              onTap: () => controller.setEntity(SearchEntityType.cinema),
            ),
            const SizedBox(width: 8),
            _buildTabChip(
              label: 'F&B',
              icon: Icons.fastfood_rounded,
              isSelected: current == SearchEntityType.fnb,
              count: controller.filteredFnb.length,
              onTap: () => controller.setEntity(SearchEntityType.fnb),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required int count,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. ACTIVE FILTERS BAR (PB-052)
  // =========================================================================

  Widget _buildActiveFilterBar(AppSearchController controller) {
    return Obx(() {
      if (!controller.hasActiveFilters) {
        return const SizedBox.shrink();
      }

      return Container(
        color: AppColors.card.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Chip Reset
              InkWell(
                onTap: controller.resetFilters,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error, width: 0.8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 13, color: AppColors.error),
                      SizedBox(width: 4),
                      Text(
                        'Reset Filter',
                        style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Chip Genre
              if (controller.selectedGenre.value != null) ...[
                _buildActiveChip(
                  label: 'Genre: ${controller.selectedGenre.value}',
                  onDelete: () => controller.setGenre(null),
                ),
                const SizedBox(width: 6),
              ],

              // Chip Rating >= 7.0
              if (controller.isHighRatingOnly.value) ...[
                _buildActiveChip(
                  label: 'Rating ≥ 7.0 ★',
                  onDelete: controller.toggleHighRating,
                ),
                const SizedBox(width: 6),
              ],

              // Chip Max Price
              if (controller.maxPrice.value != null) ...[
                _buildActiveChip(
                  label: '≤ ${CurrencyHelper.format(controller.maxPrice.value!)}',
                  onDelete: () => controller.setMaxPrice(null),
                ),
                const SizedBox(width: 6),
              ],

              // Chip Kota Bioskop
              if (controller.selectedCity.value != null) ...[
                _buildActiveChip(
                  label: 'Kota: ${controller.selectedCity.value}',
                  onDelete: () => controller.setCity(null),
                ),
                const SizedBox(width: 6),
              ],

              // Chip Sorting
              if (controller.selectedSort.value != SearchSortOption.relevance) ...[
                _buildActiveChip(
                  label: _getSortLabel(controller.selectedSort.value),
                  onDelete: () =>
                      controller.setSortOption(SearchSortOption.relevance),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActiveChip({
    required String label,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. SEARCH HISTORY SECTION (PB-054) - Max 5 Items
  // =========================================================================

  Widget _buildSearchHistorySection(AppSearchController controller) {
    return Obx(() {
      final history = controller.searchHistory;

      if (history.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Temukan Segalanya di Cinemate',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ketik judul film, lokasi bioskop, atau menu snack favoritmu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    'Riwayat Pencarian Terakhir',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: controller.clearAllHistory,
                child: const Text(
                  'Hapus Semua',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...history.map((query) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.query_builder_rounded,
                      color: AppColors.textSecondary, size: 18),
                  title: Text(
                    query,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 16),
                    onPressed: () => controller.removeHistoryItem(query),
                  ),
                  onTap: () => controller.selectHistoryItem(query),
                ),
              )),
        ],
      );
    });
  }

  // =========================================================================
  // 5. SEARCH RESULTS (PB-051, PB-052, PB-053)
  // =========================================================================

  Widget _buildSearchResults(AppSearchController controller) {
    final entity = controller.selectedEntity.value;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Ringkasan Jumlah Hasil
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Ditemukan ${controller.totalResultCount} hasil pencarian',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // ── Bagian Film ───────────────────────────────────────────────────────
        if ((entity == SearchEntityType.all ||
                entity == SearchEntityType.movie) &&
            controller.filteredMovies.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Film (${controller.filteredMovies.length})',
            icon: Icons.movie_rounded,
          ),
          const SizedBox(height: 8),
          ...controller.filteredMovies.map((movie) => _buildMovieCard(movie, controller)),
          const SizedBox(height: 16),
        ],

        // ── Bagian Bioskop ───────────────────────────────────────────────────
        if ((entity == SearchEntityType.all ||
                entity == SearchEntityType.cinema) &&
            controller.filteredCinemas.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Bioskop (${controller.filteredCinemas.length})',
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 8),
          ...controller.filteredCinemas
              .map((cinema) => _buildCinemaCard(cinema, controller)),
          const SizedBox(height: 16),
        ],

        // ── Bagian F&B ───────────────────────────────────────────────────────
        if ((entity == SearchEntityType.all ||
                entity == SearchEntityType.fnb) &&
            controller.filteredFnb.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Makanan & Minuman (${controller.filteredFnb.length})',
            icon: Icons.fastfood_rounded,
          ),
          const SizedBox(height: 8),
          ...controller.filteredFnb.map((fnb) => _buildFnbCard(fnb)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Card Film ─────────────────────────────────────────────────────────────
  Widget _buildMovieCard(MovieModel movie, AppSearchController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.openMovieDetail(movie),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 65,
                    height: 95,
                    child: movie.posterUrl.isNotEmpty
                        ? Image.network(
                            movie.posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.movie_rounded,
                                  color: AppColors.textSecondary, size: 28),
                            ),
                          )
                        : Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.movie_rounded,
                                color: AppColors.textSecondary, size: 28),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Informasi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text(
                            movie.formattedRating,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            movie.releaseYear,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            movie.formattedDuration,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie.genreString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tombol Aksi Beli Tiket Langsung
                      Row(
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () => controller.bookMovie(movie),
                            child: const Text(
                              'Pesan Tiket',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
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
        ),
      ),
    );
  }

  // ── Card Bioskop ──────────────────────────────────────────────────────────
  Widget _buildCinemaCard(CinemaModel cinema, AppSearchController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.theater_comedy_rounded,
              color: AppColors.primary, size: 24),
        ),
        title: Text(
          cinema.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              cinema.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cinema.city,
                    style: const TextStyle(
                      color: AppColors.info,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (cinema.distanceKm != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${cinema.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: () => controller.openCinema(cinema),
          child: const Text(
            'Jadwal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ── Card F&B ──────────────────────────────────────────────────────────────
  Widget _buildFnbCard(FnbItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fastfood_rounded,
              color: AppColors.warning, size: 22),
        ),
        title: Text(
          item.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              item.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  CurrencyHelper.format(item.price),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 6. STATE KOSONG & SKELETON LOADING (PB-055)
  // =========================================================================

  Widget _buildEmptyState(AppSearchController controller) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 54,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Tidak Ada Hasil Ditemukan',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ditemukan film, bioskop, atau menu untuk kata kunci "${controller.searchQuery.value}".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Saran: Coba periksa kembali ejaan kata kunci atau sesuaikan filter pencarian.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: controller.resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Filter & Cari Ulang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 90,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // 7. MODAL BOTTOM SHEET FILTER & SORTING (PB-052, PB-053)
  // =========================================================================

  void _showFilterBottomSheet(
      BuildContext context, AppSearchController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Header Sheet
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter & Pengurutan',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.resetFilters();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Reset Semua',
                        style: TextStyle(color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 8),

                // ── Pengurutan Hasil (PB-053) ─────────────────────────────────
                const Text(
                  'Urutkan Berdasarkan',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSortChip(
                          label: 'Paling Populer',
                          option: SearchSortOption.relevance,
                          controller: controller,
                        ),
                        _buildSortChip(
                          label: 'Rating Tertinggi ★',
                          option: SearchSortOption.ratingDesc,
                          controller: controller,
                        ),
                        _buildSortChip(
                          label: 'Harga Termurah',
                          option: SearchSortOption.priceAsc,
                          controller: controller,
                        ),
                        _buildSortChip(
                          label: 'Jarak Terdekat (km)',
                          option: SearchSortOption.distanceAsc,
                          controller: controller,
                        ),
                        _buildSortChip(
                          label: 'Abjad (A - Z)',
                          option: SearchSortOption.nameAsc,
                          controller: controller,
                        ),
                      ],
                    )),
                const SizedBox(height: 18),

                // ── Filter Genre Film (PB-052) ────────────────────────────────
                const Text(
                  'Genre Film',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.availableGenres.map((genre) {
                        final isSelected =
                            controller.selectedGenre.value == genre;
                        return ChoiceChip(
                          label: Text(genre),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.card,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          onSelected: (_) => controller.setGenre(genre),
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 18),

                // ── Filter Rating Minimal (PB-052) ───────────────────────────
                const Text(
                  'Kualitas Rating',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Hanya Rating Tinggi (≥ 7.0 ★)',
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Menyaring film berkualitas dengan ulasan tinggi',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                      activeThumbColor: AppColors.primary,
                      value: controller.isHighRatingOnly.value,
                      onChanged: (_) => controller.toggleHighRating(),
                    )),
                const SizedBox(height: 12),

                // ── Filter Batas Harga Maksimal F&B (PB-052) ──────────────────
                const Text(
                  'Harga Maksimal F&B',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.availablePrices.map((price) {
                        final isSelected = controller.maxPrice.value == price;
                        return ChoiceChip(
                          label: Text('≤ ${CurrencyHelper.format(price)}'),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.card,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          onSelected: (_) => controller.setMaxPrice(price),
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 18),

                // ── Filter Kota Bioskop (PB-052) ──────────────────────────────
                const Text(
                  'Kota Bioskop',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.availableCities.map((city) {
                        final isSelected = controller.selectedCity.value == city ||
                            (city == 'Semua Kota' &&
                                controller.selectedCity.value == null);
                        return ChoiceChip(
                          label: Text(city),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.card,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          onSelected: (_) => controller.setCity(city),
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 24),

                // Tombol Terapkan
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip({
    required String label,
    required SearchSortOption option,
    required AppSearchController controller,
  }) {
    final isSelected = controller.selectedSort.value == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontSize: 12,
      ),
      onSelected: (_) => controller.setSortOption(option),
    );
  }

  String _getSortLabel(SearchSortOption option) {
    switch (option) {
      case SearchSortOption.ratingDesc:
        return 'Urut: Rating Tertinggi';
      case SearchSortOption.priceAsc:
        return 'Urut: Harga Termurah';
      case SearchSortOption.distanceAsc:
        return 'Urut: Jarak Terdekat';
      case SearchSortOption.nameAsc:
        return 'Urut: Abjad (A - Z)';
      case SearchSortOption.relevance:
        return 'Urut: Paling Populer';
    }
  }
}
