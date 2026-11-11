// lib/controllers/cinema_controller.dart
// Controller untuk memuat data bioskop, deteksi GPS, filter radius & kalkulasi jarak (PB-015, PB-042 - PB-047)
// Menggunakan GetX State Management & Location-Based Services (LBS).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cinema_model.dart';
import '../services/cinema_service.dart';
import '../services/location_service.dart';

export '../services/location_service.dart' show LocationPreset;

class CinemaController extends GetxController {
  final CinemaService _cinemaService = CinemaService();
  final LocationService _locationService = LocationService();

  /// Semua bioskop yang tersedia
  final allCinemas = <CinemaModel>[].obs;

  /// Semua bioskop dengan jarak yang sudah dihitung dari userLat & userLng
  final cinemasWithDistance = <CinemaModel>[].obs;

  /// Daftar bioskop hasil filter radius terurut dari yang paling dekat (PB-043, PB-045)
  final filteredCinemas = <CinemaModel>[].obs;

  /// 3 bioskop terdekat untuk section dashboard (PB-015)
  final nearestCinemas = <CinemaModel>[].obs;

  /// Bioskop yang sedang aktif/dipilih di peta
  final Rxn<CinemaModel> selectedCinemaOnMap = Rxn<CinemaModel>();

  /// State loading
  final isLoading = false.obs;
  final isDetectingLocation = false.obs;

  /// Indikator apakah data berasal dari cache Hive
  final isFromCache = false.obs;

  /// Titik lokasi pengguna saat ini (Default: Jakarta Pusat)
  final userLat = (-6.1754).obs;
  final userLng = (106.8272).obs;
  final selectedLocationName = 'Jakarta Pusat (Monas)'.obs;

  /// Filter radius yang dipilih (null = Semua, 1.0, 3.0, 5.0, 10.0, 25.0) (PB-045)
  final Rxn<double> selectedRadiusKm = Rxn<double>();

  /// Daftar lokasi preset kota acuan untuk backward compatibility & fallback (PB-047)
  static List<LocationPreset> get presets => LocationService.presets;

  @override
  void onInit() {
    super.onInit();
    _loadLastLocation();
    fetchCinemas();
  }

  /// Membaca lokasi tersimpan terakhir jika ada
  void _loadLastLocation() {
    final last = _locationService.getLastKnownLocation();
    userLat.value = last.lat;
    userLng.value = last.lng;
    selectedLocationName.value = last.name;
  }

  /// Memuat daftar bioskop dari Supabase atau Hive cache
  Future<void> fetchCinemas({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      final result =
          await _cinemaService.getAllCinemas(forceRefresh: forceRefresh);
      allCinemas.assignAll(result.cinemas);
      isFromCache.value = result.fromCache;
      _recalculateDistances();
    } catch (e) {
      Get.log('[CinemaController] Error fetching cinemas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Menghitung ulang jarak seluruh bioskop ke koordinat saat ini dan mengaplikasikan filter (PB-043)
  void _recalculateDistances() {
    if (allCinemas.isEmpty) {
      cinemasWithDistance.clear();
      filteredCinemas.clear();
      nearestCinemas.clear();
      return;
    }

    // 1. Hitung seluruh bioskop terurut jarak
    final allSorted = _cinemaService.getCinemasSortedByDistance(
      allCinemas,
      userLat: userLat.value,
      userLng: userLng.value,
    );
    cinemasWithDistance.assignAll(allSorted);

    // 2. Filter berdasarkan radius aktif (PB-045)
    final filtered = _cinemaService.getCinemasSortedByDistance(
      allCinemas,
      userLat: userLat.value,
      userLng: userLng.value,
      maxRadiusKm: selectedRadiusKm.value,
    );
    filteredCinemas.assignAll(filtered);

    // 3. Top 3 bioskop terdekat untuk ringkasan dashboard
    nearestCinemas.assignAll(allSorted.take(3).toList());

    // Perbarui juga bioskop terpilih di peta jika ada
    if (selectedCinemaOnMap.value != null) {
      final updated = filteredCinemas.firstWhereOrNull(
        (c) => c.id == selectedCinemaOnMap.value!.id,
      );
      if (updated != null) {
        selectedCinemaOnMap.value = updated;
      }
    }
  }

  /// Deteksi posisi GPS pengguna saat ini secara real-time (PB-042)
  Future<bool> detectCurrentLocation() async {
    try {
      isDetectingLocation.value = true;
      final position = await _locationService.getCurrentPosition();

      if (position != null) {
        userLat.value = position.latitude;
        userLng.value = position.longitude;
        selectedLocationName.value = 'Lokasi GPS Saya';
        _recalculateDistances();

        Get.snackbar(
          'Lokasi Terdeteksi',
          'Koordinat GPS diperbarui (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1A1A2E),
          colorText: Colors.white,
          icon:
              const Icon(Icons.my_location_rounded, color: Colors.greenAccent),
          duration: const Duration(seconds: 3),
        );
        return true;
      } else {
        Get.snackbar(
          'GPS Tidak Tersedia',
          'Pastikan GPS aktif dan izin lokasi diberikan. Anda dapat memilih kota acuan manual.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1A1A2E),
          colorText: Colors.white,
          icon: const Icon(Icons.location_off_rounded, color: Colors.amber),
          duration: const Duration(seconds: 4),
        );
        return false;
      }
    } catch (e) {
      Get.log('[CinemaController] Error detecting GPS: $e');
      return false;
    } finally {
      isDetectingLocation.value = false;
    }
  }

  /// Mengubah filter radius (null = semua jarak, 1, 3, 5, 10, 25 km) (PB-045)
  void setRadius(double? radiusKm) {
    selectedRadiusKm.value = radiusKm;
    _recalculateDistances();
  }

  /// Mengatur titik lokasi acuan manual secara fleksibel (PB-047)
  void setManualLocation(LocationPreset preset) {
    selectedLocationName.value = preset.name;
    userLat.value = preset.latitude;
    userLng.value = preset.longitude;
    _locationService.saveLastKnownLocation(
      preset.latitude,
      preset.longitude,
      preset.name,
    );
    _recalculateDistances();
  }

  /// Mengubah titik lokasi dengan nama dan koordinat (kompatibilitas kode sebelumnya)
  void setLocation(String name, double lat, double lng) {
    selectedLocationName.value = name;
    userLat.value = lat;
    userLng.value = lng;
    _locationService.saveLastKnownLocation(lat, lng, name);
    _recalculateDistances();
  }

  /// Memilih bioskop di peta untuk memunculkan panel ringkasan
  void selectCinemaOnMap(CinemaModel? cinema) {
    selectedCinemaOnMap.value = cinema;
  }

  /// Membuka aplikasi Google Maps eksternal untuk rute navigasi menuju bioskop (PB-046)
  Future<void> openGoogleMapsRoute(CinemaModel cinema) async {
    // 1. URL universal Google Maps Directions
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${cinema.latitude},${cinema.longitude}&destination_place_id=${Uri.encodeComponent(cinema.name)}&travelmode=driving',
    );

    // 2. Fallback geo URI
    final geoUrl = Uri.parse(
      'geo:${cinema.latitude},${cinema.longitude}?q=${cinema.latitude},${cinema.longitude}(${Uri.encodeComponent(cinema.name)})',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Navigasi Gagal',
          'Tidak dapat membuka aplikasi peta. Koordinat: ${cinema.latitude}, ${cinema.longitude}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1A1A2E),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.log('[CinemaController] Error launching navigation map: $e');
      Get.snackbar(
        'Info Rute',
        'Alamat ${cinema.name}: ${cinema.address}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1A1A2E),
        colorText: Colors.white,
      );
    }
  }
}
