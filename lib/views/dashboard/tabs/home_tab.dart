// lib/views/dashboard/tabs/home_tab.dart
// Tab utama: Banner Carousel, Now Playing, dan Coming Soon (PB-012)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/movie_controller.dart';
import '../../../models/movie_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_colors.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/shimmer_loading.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final PageController _pageController;
  Timer? _carouselTimer;

  MovieController get _movieCtrl => Get.find<MovieController>();
  AuthController get _authCtrl => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final count = _movieCtrl.bannerMovies.length;
      if (count <= 1) return;
      final nextPage = (_movieCtrl.bannerIndex.value + 1) % count;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.movie_filter_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'CINEMATE',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Belum ada notifikasi baru untuk saat ini.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => _movieCtrl.fetchAllMovies(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salam Pengguna
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  final user = _authCtrl.currentUser.value;
                  final name = user?.fullName.isNotEmpty == true ? user!.fullName : 'Pengguna';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $name! 👋',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mau nonton film apa hari ini?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 12),

              // =============================================================
              // INDIKATOR MODE OFFLINE & HIVE CACHE (PB-013)
              // =============================================================
              Obx(() {
                if (!_movieCtrl.isOfflineMode.value) return const SizedBox.shrink();

                final cached = _movieCtrl.lastCacheTime.value;
                final timeStr = cached != null
                    ? '${cached.hour.toString().padLeft(2, '0')}:${cached.minute.toString().padLeft(2, '0')}'
                    : 'Baru saja';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Mode Offline',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Hive (TTL 6 Jam)',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Data film dimuat dari cache lokal (tersimpan: $timeStr WIB).',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.warning, size: 20),
                        tooltip: 'Muat Ulang',
                        onPressed: () => _movieCtrl.fetchAllMovies(forceRefresh: true),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 12),

              // =============================================================
              // 1. CAROUSEL BANNER (PB-012)
              // =============================================================
              Obx(() {
                if (_movieCtrl.isLoadingBanner.value) {
                  return const BannerCarouselSkeleton();
                }

                final banners = _movieCtrl.bannerMovies;
                if (banners.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: banners.length,
                        onPageChanged: (idx) => _movieCtrl.onBannerPageChanged(idx),
                        itemBuilder: (context, index) {
                          final movie = banners[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _buildBannerCard(context, movie),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Dot Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        banners.length,
                        (index) => Obx(() {
                          final isSelected = _movieCtrl.bannerIndex.value == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isSelected ? 22 : 6,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 26),

              // =============================================================
              // 2. SEDANG TAYANG / NOW PLAYING (PB-012)
              // =============================================================
              _buildSectionHeader(
                title: 'Sedang Tayang',
                subtitle: 'Now Playing',
                onSeeAll: () {},
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (_movieCtrl.isLoadingNowPlaying.value) {
                  return const MovieListSkeleton();
                }

                final list = _movieCtrl.nowPlayingMovies;
                return SizedBox(
                  height: 250,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final movie = list[index];
                      return MovieCard(
                        movie: movie,
                        isUpcoming: false,
                        onTap: () => _openMovieDetail(context, movie),
                      );
                    },
                  ),
                );
              }),

              const SizedBox(height: 24),

              // =============================================================
              // 3. SEGERA TAYANG / COMING SOON (PB-012)
              // =============================================================
              _buildSectionHeader(
                title: 'Segera Tayang',
                subtitle: 'Coming Soon',
                onSeeAll: () {},
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (_movieCtrl.isLoadingUpcoming.value) {
                  return const MovieListSkeleton();
                }

                final list = _movieCtrl.upcomingMovies;
                return SizedBox(
                  height: 250,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final movie = list[index];
                      return MovieCard(
                        movie: movie,
                        isUpcoming: true,
                        onTap: () => _openMovieDetail(context, movie),
                      );
                    },
                  ),
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context, MovieModel movie) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openMovieDetail(context, movie),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Backdrop Image
            Positioned.fill(
              child: Image.network(
                movie.backdropUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.card,
                  child: const Center(
                    child: Icon(Icons.movie_outlined, size: 48, color: AppColors.textDisabled),
                  ),
                ),
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Konten Banner
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TRENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            movie.formattedRating,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    movie.genreString,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($subtitle)',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'Lihat Semua',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membuka halaman detail film menggunakan Get.toNamed(Routes.movieDetail, arguments: movie) (PB-014)
  void _openMovieDetail(BuildContext context, MovieModel movie) {
    Get.toNamed(Routes.movieDetail, arguments: movie);
  }
}
