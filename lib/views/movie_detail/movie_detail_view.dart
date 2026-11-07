// lib/views/movie_detail/movie_detail_view.dart
// Halaman Detail Film (PB-014)
// Menerima data movie dari Get.toNamed(Routes.movieDetail, arguments: movie)
// Menampilkan: backdrop, poster, sinopsis, genre chips, durasi, rating bintang, dan tombol "Beli Tiket"

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/movie_model.dart';
import '../../utils/app_colors.dart';

class MovieDetailView extends StatelessWidget {
  final MovieModel? movieParam;

  const MovieDetailView({super.key, this.movieParam});

  @override
  Widget build(BuildContext context) {
    // Menerima argumen dari Get.arguments atau ModalRoute
    final MovieModel? movie = movieParam ??
        (Get.arguments as MovieModel?) ??
        (ModalRoute.of(context)?.settings.arguments as MovieModel?);

    if (movie == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Detail Film'),
        ),
        body: const Center(
          child: Text(
            'Data film tidak ditemukan.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. BACKDROP SLIVER APP BAR ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  child: IconButton(
                    icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
                    onPressed: () {
                      Get.snackbar(
                        'Tersimpan',
                        'Film "${movie.title}" ditambahkan ke daftar tonton.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop image
                  Image.network(
                    movie.backdropUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.card,
                      child: const Center(
                        child: Icon(Icons.movie_outlined, size: 60, color: AppColors.textDisabled),
                      ),
                    ),
                  ),

                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          AppColors.background.withValues(alpha: 0.8),
                          AppColors.background,
                        ],
                        stops: const [0.3, 0.75, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 2. INFORMASI UTAMA FILM (POSTER, RATING, DURASI, GENRE) ───────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster Film
                      Hero(
                        tag: 'movie_poster_${movie.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 110,
                            height: 160,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Image.network(
                              movie.posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.movie_outlined, color: AppColors.textDisabled),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Info Singkat Film
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Rating Bintang Emas
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  movie.formattedRating,
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '/ 10',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${movie.voteCount} vote)',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Durasi & Tahun Rilis
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, color: AppColors.textSecondary, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        movie.formattedDuration,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        movie.releaseYear,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Genre Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.genreNames.map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 20),

                  // ── 3. SINOPSIS ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sinopsis Cerita',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    movie.overview.isNotEmpty ? movie.overview : 'Sinopsis film belum tersedia.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Informasi Tambahan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Popularitas', movie.popularity.toStringAsFixed(0)),
                        _buildStatItem('Bahasa', 'Indonesia / En'),
                        _buildStatItem('Format', '2D / IMAX'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Ruang untuk sticky bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // ── 4. STICKY BOTTOM BAR (TOMBOL BELI TIKET) ──────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.divider, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Kolom Info Harga
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Harga Tiket',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Rp 50.000',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 20),

              // Tombol Beli Tiket (PB-014)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.snackbar(
                      'Pemesanan Tiket',
                      'Lanjut ke pemilihan bioskop dan jadwal untuk "${movie.title}" (PB-018 / PB-019)',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.card,
                      colorText: AppColors.textPrimary,
                      duration: const Duration(seconds: 3),
                    );
                  },
                  icon: const Icon(Icons.confirmation_number_rounded),
                  label: const Text('Beli Tiket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
