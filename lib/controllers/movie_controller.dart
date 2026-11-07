// lib/controllers/movie_controller.dart
// Controller state management untuk katalog film, banner, & cache Hive offline (PB-012, PB-013)

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

  // ── Hive Cache & Offline State (PB-013) ────────────────────────────────────
  final isOfflineMode = false.obs;
  final isCacheExpired = false.obs;
  final Rx<DateTime?> lastCacheTime = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchAllMovies();
  }

  /// Memuat semua data film (Banner, Now Playing, dan Coming Soon)
  Future<void> fetchAllMovies({bool forceRefresh = false}) async {
    isOfflineMode.value = false;
    await Future.wait([
      fetchBannerMovies(forceRefresh: forceRefresh),
      fetchNowPlaying(forceRefresh: forceRefresh),
      fetchUpcoming(forceRefresh: forceRefresh),
    ]);
  }

  Future<void> fetchBannerMovies({bool forceRefresh = false}) async {
    isLoadingBanner.value = true;
    try {
      final res = await _service.getBannerMovies(forceRefresh: forceRefresh);
      bannerMovies.assignAll(res.movies);
      if (res.fromCache) {
        isOfflineMode.value = true;
      }
    } catch (_) {
      isOfflineMode.value = true;
    } finally {
      isLoadingBanner.value = false;
    }
  }

  Future<void> fetchNowPlaying({bool forceRefresh = false}) async {
    isLoadingNowPlaying.value = true;
    try {
      final res = await _service.getNowPlaying(forceRefresh: forceRefresh);
      nowPlayingMovies.assignAll(res.movies);
      if (res.fromCache) {
        isOfflineMode.value = true;
        isCacheExpired.value = res.isExpired;
        lastCacheTime.value = res.timestamp;
      }
    } catch (_) {
      isOfflineMode.value = true;
    } finally {
      isLoadingNowPlaying.value = false;
    }
  }

  Future<void> fetchUpcoming({bool forceRefresh = false}) async {
    isLoadingUpcoming.value = true;
    try {
      final res = await _service.getUpcoming(forceRefresh: forceRefresh);
      upcomingMovies.assignAll(res.movies);
      if (res.fromCache) {
        isOfflineMode.value = true;
        isCacheExpired.value = res.isExpired;
        lastCacheTime.value = res.timestamp;
      }
    } catch (_) {
      isOfflineMode.value = true;
    } finally {
      isLoadingUpcoming.value = false;
    }
  }

  void onBannerPageChanged(int index) {
    bannerIndex.value = index;
  }
}
