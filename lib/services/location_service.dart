// lib/services/location_service.dart
// Service pendeteksi GPS perangkat dan penyedia fallback lokasi manual (PB-042, PB-047)
// Referensi: SRS Â§3.8 FR-046, FR-051, Modul VII Notification & LBS

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

class LocationPreset {
  final String name;
  final String city;
  final String description;
  final double latitude;
  final double longitude;

  const LocationPreset({
    required this.name,
    required this.city,
    required this.description,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  final GetStorage _storage = GetStorage();

  static const String keyLastLat = 'last_user_lat';
  static const String keyLastLng = 'last_user_lng';
  static const String keyLastLocName = 'last_user_loc_name';

  /// Daftar kota & titik acuan manual jika GPS mati, izin ditolak, atau mode offline (PB-047)
  static const List<LocationPreset> presets = [
    LocationPreset(
      name: 'Jakarta Pusat (Monas)',
      city: 'Jakarta',
      description: 'Pusat kota, dekat Gambir & Thamrin',
      latitude: -6.1754,
      longitude: 106.8272,
    ),
    LocationPreset(
      name: 'Jakarta Selatan (Senayan)',
      city: 'Jakarta',
      description: 'Dekat GBK & FX Sudirman',
      latitude: -6.2176,
      longitude: 106.8013,
    ),
    LocationPreset(
      name: 'Jakarta Utara (Kelapa Gading)',
      city: 'Jakarta',
      description: 'Kawasan Mal Kelapa Gading',
      latitude: -6.1601,
      longitude: 106.9013,
    ),
    LocationPreset(
      name: 'Depok (Margonda)',
      city: 'Depok',
      description: 'Dekat Kampus UI & Margo City',
      latitude: -6.3728,
      longitude: 106.8318,
    ),
    LocationPreset(
      name: 'Tangerang (Karawaci)',
      city: 'Tangerang',
      description: 'Dekat Supermal Karawaci',
      latitude: -6.2255,
      longitude: 106.6080,
    ),
    LocationPreset(
      name: 'Bandung (Paris Van Java)',
      city: 'Bandung',
      description: 'Kawasan Sukajadi & Gedung Sate',
      latitude: -6.8906,
      longitude: 107.5960,
    ),
    LocationPreset(
      name: 'Surabaya (Tunjungan)',
      city: 'Surabaya',
      description: 'Pusat kota Surabaya & Tunjungan Plaza',
      latitude: -7.2618,
      longitude: 112.7388,
    ),
    LocationPreset(
      name: 'Yogyakarta (Ambarrukmo)',
      city: 'Yogyakarta',
      description: 'Dekat Plaza Ambarrukmo & Malioboro',
      latitude: -7.7828,
      longitude: 110.4011,
    ),
    LocationPreset(
      name: 'Medan (Centre Point)',
      city: 'Medan',
      description: 'Pusat kota Medan & Mall Centre Point',
      latitude: 3.5925,
      longitude: 98.6811,
    ),
    LocationPreset(
      name: 'Bali (Kuta / Beachwalk)',
      city: 'Bali',
      description: 'Kawasan Pantai Kuta & Beachwalk Mall',
      latitude: -8.7180,
      longitude: 115.1691,
    ),
  ];

  /// Memeriksa apakah layanan GPS perangkat aktif
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[LocationService] isLocationServiceEnabled error: $e');
      return false;
    }
  }

  /// Memeriksa status izin lokasi saat ini
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('[LocationService] checkPermission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Meminta izin lokasi ke pengguna
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('[LocationService] requestPermission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Mendapatkan posisi koordinat GPS terkini dengan timeout dan penanganan graceful
  Future<Position?> getCurrentPosition({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        debugPrint('[LocationService] Layanan GPS perangkat nonaktif.');
        return null;
      }

      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Izin lokasi ditolak oleh pengguna.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Izin lokasi ditolak permanen.');
        return null;
      }

      // Ambil posisi real-time dengan akurasi medium-high
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Simpan koordinat terakhir ke storage
      await saveLastKnownLocation(
        position.latitude,
        position.longitude,
        'Lokasi GPS Saya',
      );

      return position;
    } catch (e) {
      debugPrint('[LocationService] Gagal mendapatkan lokasi GPS: $e');
      // Coba ambil last known position
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) return lastPos;
      } catch (_) {}
      return null;
    }
  }

  /// Menyimpan lokasi terakhir ke GetStorage
  Future<void> saveLastKnownLocation(
    double lat,
    double lng,
    String name,
  ) async {
    await _storage.write(keyLastLat, lat);
    await _storage.write(keyLastLng, lng);
    await _storage.write(keyLastLocName, name);
  }

  /// Membaca lokasi tersimpan terakhir
  ({double lat, double lng, String name}) getLastKnownLocation() {
    final lat = _storage.read<double>(keyLastLat) ?? -6.1754;
    final lng = _storage.read<double>(keyLastLng) ?? 106.8272;
    final name =
        _storage.read<String>(keyLastLocName) ?? 'Jakarta Pusat (Monas)';
    return (lat: lat, lng: lng, name: name);
  }

  /// Membuka pengaturan aplikasi di perangkat
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Membuka pengaturan lokasi perangkat
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
