// lib/controllers/movie_controller.dart
// Controller state management untuk katalog film & banner carousel (PB-012)

import 'package:get/get.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';

class MovieController extends GetxController {
  final MovieService _service;

  MovieController({MovieService? service})
      : _service = service ?? MovieService();

  // ── Observable State ──────────────────────────────────────────────────────
  final bannerMovies = <MovieModel>[].obs;
  final nowPlayingMovies = <MovieModel>[].obs;
  final upcomingMovies = <MovieModel>[].obs;

  final isLoadingBanner = true.obs;
  final isLoadingNowPlaying = true.obs;
  final isLoadingUpcoming = true.obs;

  final bannerIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllMovies();
  }

  /// Memuat semua data film (Banner, Now Playing, dan Coming Soon)
  Future<void> fetchAllMovies() async {
    await Future.wait([
      fetchBannerMovies(),
      fetchNowPlaying(),
      fetchUpcoming(),
    ]);
  }

  Future<void> fetchBannerMovies() async {
    isLoadingBanner.value = true;
    try {
      final movies = await _service.getBannerMovies();
      bannerMovies.assignAll(movies);
    } catch (_) {
      // Sedia fallback
    } finally {
      isLoadingBanner.value = false;
    }
  }

  Future<void> fetchNowPlaying() async {
    isLoadingNowPlaying.value = true;
    try {
      final movies = await _service.getNowPlaying();
      nowPlayingMovies.assignAll(movies);
    } catch (_) {
      // Sedia fallback
    } finally {
      isLoadingNowPlaying.value = false;
    }
  }

  Future<void> fetchUpcoming() async {
    isLoadingUpcoming.value = true;
    try {
      final movies = await _service.getUpcoming();
      upcomingMovies.assignAll(movies);
    } catch (_) {
      // Sedia fallback
    } finally {
      isLoadingUpcoming.value = false;
    }
  }

  void onBannerPageChanged(int index) {
    bannerIndex.value = index;
  }
}
