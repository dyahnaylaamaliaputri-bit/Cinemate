// lib/services/cinema_service.dart
// Service untuk mengambil data bioskop dari Supabase & menghitung bioskop terdekat (PB-015, PB-043, PB-045)
// Mendukung offline caching dengan Hive, seed data multi-kota, dan filter radius.

import 'package:flutter/foundation.dart';
import '../models/cinema_model.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class CinemaService {
  CinemaService._internal();
  static final CinemaService _instance = CinemaService._internal();
  factory CinemaService() => _instance;

  final SupabaseService _supabase = SupabaseService();
  final StorageService _storage = StorageService();

  /// Data fallback bioskop jika database Supabase offline tanpa cache
  static const List<Map<String, dynamic>> seedCinemas = [
    {
      'id': '126eef40-67fb-4aee-b4f7-11929e296767',
      'name': 'Cinemate Plaza',
      'address': 'Jl. Sudirman No. 1, Jakarta Pusat',
      'latitude': -6.2088,
      'longitude': 106.8456,
      'city': 'Jakarta',
      'image_url': null,
    },
    {
      'id': '4a36b557-bc18-4017-94b5-807fedd2900b',
      'name': 'Nusantara XXI Fiktif',
      'address': 'Jl. Gatot Subroto No. 25, Jakarta Sel.',
      'latitude': -6.2297,
      'longitude': 106.8295,
      'city': 'Jakarta',
      'image_url': null,
    },
    {
      'id': 'd956c35c-2486-4b51-93f1-effe30152db1',
      'name': 'Metro Cinema Senayan',
      'address': 'Jl. Asia Afrika No. 8, Jakarta Selatan',
      'latitude': -6.2176,
      'longitude': 106.8013,
      'city': 'Jakarta',
      'image_url': null,
    },
    {
      'id': 'bcdb8533-41f1-46b6-9e67-24c23a85d8ab',
      'name': 'Cinemate Kelapa Gading',
      'address': 'Jl. Boulevard Raya, Jakarta Utara',
      'latitude': -6.1601,
      'longitude': 106.9013,
      'city': 'Jakarta',
      'image_url': null,
    },
    {
      'id': '543bc912-a72c-4bdf-9eba-e0c625c7b63f',
      'name': 'Bintang Cinema Depok',
      'address': 'Jl. Margonda Raya No. 50, Depok',
      'latitude': -6.3728,
      'longitude': 106.8318,
      'city': 'Depok',
      'image_url': null,
    },
    {
      'id': '78a1bc23-6621-4d32-8df1-123456789abc',
      'name': 'Cinemate Paris Van Java',
      'address': 'Jl. Sukajadi No. 137-139, Bandung',
      'latitude': -6.8893,
      'longitude': 107.5962,
      'city': 'Bandung',
      'image_url': null,
    },
    {
      'id': '89b2cd34-7732-4e43-9ef2-234567890bcd',
      'name': 'Nusantara XXI Tunjungan Plaza',
      'address': 'Jl. Basuki Rahmat No. 8-12, Surabaya',
      'latitude': -7.2618,
      'longitude': 112.7388,
      'city': 'Surabaya',
      'image_url': null,
    },
    {
      'id': '90c3de45-8843-4f54-0fa3-345678901cde',
      'name': 'Cinemate Plaza Ambarrukmo',
      'address': 'Jl. Laksda Adisucipto No. 80, Yogyakarta',
      'latitude': -7.7828,
      'longitude': 110.4011,
      'city': 'Yogyakarta',
      'image_url': null,
    },
    {
      'id': 'a1d4ef56-9954-4a65-1ab4-456789012def',
      'name': 'Cinemate Supermal Karawaci',
      'address': 'Boulevard Diponegoro No. 105, Tangerang',
      'latitude': -6.2255,
      'longitude': 106.6080,
      'city': 'Tangerang',
      'image_url': null,
    },
    {
      'id': 'b2e5fa67-0065-4b76-2bc5-567890123efa',
      'name': 'Nusantara XXI Centre Point Medan',
      'address': 'Jl. Timor Blok H No. 1, Medan',
      'latitude': 3.5925,
      'longitude': 98.6811,
      'city': 'Medan',
      'image_url': null,
    },
    {
      'id': 'c3f6ab78-1176-4c87-3cd6-678901234fab',
      'name': 'Cinemate Beachwalk Kuta Bali',
      'address': 'Jl. Pantai Kuta, Badung, Bali',
      'latitude': -8.7180,
      'longitude': 115.1691,
      'city': 'Bali',
      'image_url': null,
    },
  ];

  /// Mengambil semua bioskop dari Supabase / Hive Cache / Fallback Seed
  Future<({List<CinemaModel> cinemas, bool fromCache})> getAllCinemas({
    bool forceRefresh = false,
  }) async {
    // 1. Cek cache Hive jika tidak forceRefresh
    if (!forceRefresh) {
      try {
        final cached = await _storage.getCachedCinemas();
        if (cached != null && cached.isNotEmpty) {
          final list = cached.map((e) => CinemaModel.fromJson(e)).toList();
          return (cinemas: list, fromCache: true);
        }
      } catch (e) {
        debugPrint('[CinemaService] Error reading Hive cache: $e');
      }
    }

    // 2. Fetch online dari Supabase database
    try {
      final response =
          await _supabase.client.from('cinemas').select().order('name');

      if (response.isNotEmpty) {
        final jsonList =
            response.map((e) => Map<String, dynamic>.from(e)).toList();

        // Simpan ke Hive cache
        await _storage.cacheCinemas(jsonList);

        final list = jsonList.map((e) => CinemaModel.fromJson(e)).toList();
        return (cinemas: list, fromCache: false);
      }
    } catch (e) {
      debugPrint('[CinemaService] Supabase fetch error: $e');
    }

    // 3. Fallback jika offline: periksa apakah ada cache lama
    try {
      final cached = await _storage.getCachedCinemas();
      if (cached != null && cached.isNotEmpty) {
        final list = cached.map((e) => CinemaModel.fromJson(e)).toList();
        return (cinemas: list, fromCache: true);
      }
    } catch (e) {
      debugPrint('[CinemaService] Error reading Hive fallback cache: $e');
    }

    // 4. Fallback terakhir: seed data lokal lengkap multi-kota
    final fallbackList =
        seedCinemas.map((e) => CinemaModel.fromJson(e)).toList();
    return (cinemas: fallbackList, fromCache: true);
  }

  /// Menghitung jarak bioskop dan mengembalikan N bioskop terdekat (default: 3)
  List<CinemaModel> getNearestCinemas(
    List<CinemaModel> cinemas, {
    required double userLat,
    required double userLng,
    int limit = 3,
  }) {
    final sorted = getCinemasSortedByDistance(
      cinemas,
      userLat: userLat,
      userLng: userLng,
    );
    return sorted.take(limit).toList();
  }

  /// Menghitung jarak seluruh bioskop ke koordinat pengguna dengan formula Haversine,
  /// mengurutkannya secara ascending (km), dan memfilter berdasarkan radius (PB-043, PB-045).
  List<CinemaModel> getCinemasSortedByDistance(
    List<CinemaModel> cinemas, {
    required double userLat,
    required double userLng,
    double? maxRadiusKm,
  }) {
    if (cinemas.isEmpty) return [];

    // Hitung jarak ke user untuk masing-masing bioskop
    final listWithDistance = cinemas.map((cinema) {
      final distance = cinema.calculateDistanceFrom(userLat, userLng);
      return cinema.copyWith(distanceKm: distance);
    }).toList();

    // Filter radius jika diset
    final filtered = maxRadiusKm != null
        ? listWithDistance
            .where((c) => (c.distanceKm ?? double.infinity) <= maxRadiusKm)
            .toList()
        : listWithDistance;

    // Urutkan ascending berdasarkan jarak terkecil
    filtered.sort((a, b) {
      final distA = a.distanceKm ?? double.infinity;
      final distB = b.distanceKm ?? double.infinity;
      return distA.compareTo(distB);
    });

    return filtered;
  }
}
