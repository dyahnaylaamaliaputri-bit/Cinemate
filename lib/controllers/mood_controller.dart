// lib/controllers/mood_controller.dart
// Controller untuk modul rekomendasi film berbasis Mood AI (PB-031, PB-032, PB-033)

import 'package:get/get.dart';
import '../models/mood_model.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../services/mood_service.dart';

class MoodController extends GetxController {
  final MoodRecommendationService _moodService;

  MoodController({MoodRecommendationService? moodService})
      : _moodService = moodService ?? MoodRecommendationService();

  /// Daftar seluruh kategori emosi yang tersedia
  final List<MoodDefinition> allMoods = MoodDefinition.allMoods;

  /// Mood yang sedang dipilih oleh pengguna
  final Rx<MoodDefinition> selectedMood =
      Rx<MoodDefinition>(MoodDefinition.allMoods.first);

  /// Daftar rekomendasi film yang dihasilkan oleh AI
  final recommendations = <MoodRecommendationItem>[].obs;

  /// Status loading rekomendasi
  final isLoading = false.obs;

  /// Pesan kesalahan jika terjadi kendala
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (recommendations.isEmpty) {
      loadRecommendations();
    }
  }

  /// Memilih kategori mood baru dan memperbarui rekomendasi film secara reaktif
  Future<void> selectMood(MoodDefinition mood, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        selectedMood.value.type == mood.type &&
        recommendations.isNotEmpty &&
        !isLoading.value) {
      return;
    }
    selectedMood.value = mood;
    await loadRecommendations(forceRefresh: forceRefresh);
  }

  /// Memuat rekomendasi film dari service (TMDB Discovery + Fallback Offline)
  Future<void> loadRecommendations({bool forceRefresh = false}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final items = await _moodService.getRecommendations(
        selectedMood.value.type,
        forceRefresh: forceRefresh,
      );
      recommendations.assignAll(items);
    } catch (e) {
      errorMessage.value = 'Gagal memuat rekomendasi: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Membuka alur pemesanan tiket bioskop langsung untuk film yang direkomendasikan
  void bookMovie(MovieModel movie) {
    Get.toNamed(Routes.bookByMovie, arguments: movie);
  }

  /// Membuka halaman detail film
  void viewMovieDetail(MovieModel movie) {
    Get.toNamed(Routes.movieDetail, arguments: movie);
  }
}
