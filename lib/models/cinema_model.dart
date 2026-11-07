// lib/models/cinema_model.dart
// Model data bioskop dengan perhitungan jarak Haversine (PB-015)
// Referensi: SRS §3.1, PB-015, tabel Supabase `cinemas`

import 'dart:math' as math;

class CinemaModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String city;
  final String? imageUrl;
  final double? distanceKm;
  final List<String> facilities;

  const CinemaModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.city = 'Jakarta',
    this.imageUrl,
    this.distanceKm,
    this.facilities = const ['Dolby Atmos', 'IMAX', 'Premiere'],
  });

  factory CinemaModel.fromJson(Map<String, dynamic> json) {
    return CinemaModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      city: json['city'] as String? ?? 'Jakarta',
      imageUrl: json['image_url'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'] as List)
          : _defaultFacilitiesFor(json['name'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'image_url': imageUrl,
      if (distanceKm != null) 'distance_km': distanceKm,
      'facilities': facilities,
    };
  }

  CinemaModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? city,
    String? imageUrl,
    double? distanceKm,
    List<String>? facilities,
  }) {
    return CinemaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      distanceKm: distanceKm ?? this.distanceKm,
      facilities: facilities ?? this.facilities,
    );
  }

  /// Menghitung jarak lurus ke koordinat pengguna menggunakan rumus Haversine (dalam kilometer)
  double calculateDistanceFrom(double userLat, double userLng) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(latitude - userLat);
    final dLon = _degreesToRadians(longitude - userLng);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(userLat)) *
            math.cos(_degreesToRadians(latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Format teks jarak terdekat (misal: "1.2 km" atau "850 m")
  String get formattedDistance {
    if (distanceKm == null) return '-';
    if (distanceKm! < 1.0) {
      final meters = (distanceKm! * 1000).round();
      return '$meters m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Fasilitas default untuk memberikan estetika detail pada kartu bioskop
  static List<String> _defaultFacilitiesFor(String cinemaName) {
    if (cinemaName.contains('XXI')) {
      return ['IMAX', 'Premiere', 'Dolby Atmos'];
    } else if (cinemaName.contains('Senayan') || cinemaName.contains('Plaza')) {
      return ['Ultra XD', 'Dolby Atmos', 'Reclining Seat'];
    } else if (cinemaName.contains('Gading')) {
      return ['4DX', 'ScreenX', 'Sweetbox'];
    }
    return ['Dolby 7.1', '2D / 3D', 'Comfort Seats'];
  }
}
