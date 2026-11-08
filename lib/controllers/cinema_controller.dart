// lib/controllers/cinema_controller.dart
// Controller untuk memuat data bioskop dan menghitung 3 bioskop terdekat (PB-015)
// Menggunakan GetX State Management & Location-Based Services (LBS).

import 'package:get/get.dart';
import '../models/cinema_model.dart';
import '../services/cinema_service.dart';

class LocationPreset {
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  const LocationPreset({
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
  });
}

class CinemaController extends GetxController {
  final CinemaService _cinemaService = CinemaService();

  /// Semua bioskop yang tersedia
  final allCinemas = <CinemaModel>[].obs;

  /// 3 bioskop terdekat yang dihitung dari posisi pengguna
  final nearestCinemas = <CinemaModel>[].obs;

  /// State loading
  final isLoading = false.obs;

  /// Indikator apakah data berasal dari cache Hive
  final isFromCache = false.obs;

  /// Titik lokasi pengguna saat ini (Default: Jakarta Pusat)
  final userLat = (-6.2000).obs;
  final userLng = (106.8167).obs;
  final selectedLocationName = 'Jakarta Pusat (Monas)'.obs;

  /// Daftar lokasi preset untuk pengujian dan demonstrasi LBS interaktif
  static const List<LocationPreset> presets = [
    LocationPreset(
      name: 'Jakarta Pusat (Monas)',
      description: 'Pusat kota, dekat Gambir & Thamrin',
      latitude: -6.1754,
      longitude: 106.8272,
    ),
    LocationPreset(
      name: 'Jakarta Selatan (Senayan)',
      description: 'Dekat GBK & FX Sudirman',
      latitude: -6.2176,
      longitude: 106.8013,
    ),
    LocationPreset(
      name: 'Jakarta Selatan (Gatot Subroto)',
      description: 'Kawasan bisnis & Kuningan',
      latitude: -6.2297,
      longitude: 106.8295,
    ),
    LocationPreset(
      name: 'Jakarta Utara (Kelapa Gading)',
      description: 'Kawasan Mal Kelapa Gading',
      latitude: -6.1601,
      longitude: 106.9013,
    ),
    LocationPreset(
      name: 'Depok (Margonda)',
      description: 'Dekat Kampus UI & Margo City',
      latitude: -6.3728,
      longitude: 106.8318,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    fetchCinemas();
  }

  /// Memuat daftar bioskop dari Supabase atau Hive cache
  Future<void> fetchCinemas({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      final result =
          await _cinemaService.getAllCinemas(forceRefresh: forceRefresh);
      allCinemas.assignAll(result.cinemas);
      isFromCache.value = result.fromCache;
      _updateNearestList();
    } catch (e) {
      Get.log('[CinemaController] Error fetching cinemas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Memperbarui daftar 3 bioskop terdekat berdasarkan koordinat saat ini
  void _updateNearestList() {
    final nearest = _cinemaService.getNearestCinemas(
      allCinemas,
      userLat: userLat.value,
      userLng: userLng.value,
      limit: 3,
    );
    nearestCinemas.assignAll(nearest);
  }

  /// Mengubah titik lokasi acuan (LBS) dan menghitung ulang jarak secara real-time
  void setLocation(String name, double lat, double lng) {
    selectedLocationName.value = name;
    userLat.value = lat;
    userLng.value = lng;
    _updateNearestList();
  }
}
