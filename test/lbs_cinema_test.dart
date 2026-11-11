// test/lbs_cinema_test.dart
// Unit test untuk modul Location-Based Services (LBS) & Peta Bioskop (PB-042 s.d. PB-047)

import 'package:cinemate/controllers/cinema_controller.dart';
import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/services/cinema_service.dart';
import 'package:cinemate/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PB-042 & PB-047: LocationService & Manual Presets Tests', () {
    test(
        'LocationService presets should contain valid Indonesian reference cities',
        () {
      final presets = LocationService.presets;
      expect(presets.length, greaterThanOrEqualTo(5));

      final jakarta = presets.firstWhere((p) => p.city == 'Jakarta');
      expect(jakarta.name, contains('Jakarta'));
      expect(jakarta.latitude, closeTo(-6.1754, 0.05));
      expect(jakarta.longitude, closeTo(106.8272, 0.05));

      final bandung = presets.firstWhere((p) => p.city == 'Bandung');
      expect(bandung.latitude, closeTo(-6.8906, 0.05));
      expect(bandung.longitude, closeTo(107.5960, 0.05));

      final surabaya = presets.firstWhere((p) => p.city == 'Surabaya');
      expect(surabaya.latitude, closeTo(-7.2618, 0.05));
      expect(surabaya.longitude, closeTo(112.7388, 0.05));
    });

    test('CinemaController should expose presets and default location', () {
      expect(CinemaController.presets.isNotEmpty, isTrue);
      final first = CinemaController.presets.first;
      expect(first.name, isNotEmpty);
      expect(first.latitude, isNotNull);
      expect(first.longitude, isNotNull);
    });
  });

  group('PB-043: Haversine Distance & Proximity Sorting Tests', () {
    const userLat = -6.1754; // Monas, Jakarta Pusat
    const userLng = 106.8272;

    final cinemaA = CinemaModel(
      id: 'c-1',
      name: 'Cinemate Dekat (Plaza)',
      address: 'Jl. Thamrin',
      latitude: -6.1931,
      longitude: 106.8228,
      city: 'Jakarta',
    );

    final cinemaB = CinemaModel(
      id: 'c-2',
      name: 'Cinemate Sedang (Senayan)',
      address: 'Jl. Asia Afrika',
      latitude: -6.2272,
      longitude: 106.7972,
      city: 'Jakarta',
    );

    final cinemaC = CinemaModel(
      id: 'c-3',
      name: 'Cinemate Jauh (Bandung)',
      address: 'Jl. Sukajadi',
      latitude: -6.8893,
      longitude: 107.5962,
      city: 'Bandung',
    );

    test('calculateDistanceFrom should accurately compute distance in km', () {
      final distA = cinemaA.calculateDistanceFrom(userLat, userLng);
      final distB = cinemaB.calculateDistanceFrom(userLat, userLng);
      final distC = cinemaC.calculateDistanceFrom(userLat, userLng);

      // Thamrin is ~2 km from Monas
      expect(distA, greaterThan(1.0));
      expect(distA, lessThan(3.5));

      // Senayan is ~6-8 km from Monas
      expect(distB, greaterThan(4.0));
      expect(distB, lessThan(10.0));

      // Bandung is ~110-140 km from Monas
      expect(distC, greaterThan(100.0));
      expect(distA, lessThan(distB));
      expect(distB, lessThan(distC));
    });

    test('formattedDistance should format meters and kilometers properly', () {
      final near = cinemaA.copyWith(distanceKm: 0.45);
      expect(near.formattedDistance, equals('450 m'));

      final far = cinemaA.copyWith(distanceKm: 3.24);
      expect(far.formattedDistance, equals('3.2 km'));

      final unknown = cinemaA.copyWith(distanceKm: null);
      expect(unknown.formattedDistance, equals('-'));
    });

    test('CinemaService getCinemasSortedByDistance should sort ascending by km',
        () {
      final service = CinemaService();
      final sorted = service.getCinemasSortedByDistance(
        [cinemaC, cinemaA, cinemaB],
        userLat: userLat,
        userLng: userLng,
      );

      expect(sorted.length, equals(3));
      expect(sorted[0].id, equals('c-1')); // Dekat
      expect(sorted[1].id, equals('c-2')); // Sedang
      expect(sorted[2].id, equals('c-3')); // Jauh
      expect(sorted[0].distanceKm!, lessThan(sorted[1].distanceKm!));
      expect(sorted[1].distanceKm!, lessThan(sorted[2].distanceKm!));
    });
  });

  group('PB-045: Filter Radius Jarak Bioskop Tests', () {
    const userLat = -6.1754;
    const userLng = 106.8272;

    final cinema1km = CinemaModel(
      id: 'c-1km',
      name: 'Bioskop 1.2km',
      address: 'Jl. Merdeka',
      latitude: -6.1850,
      longitude: 106.8272,
      city: 'Jakarta',
    );

    final cinema4km = CinemaModel(
      id: 'c-4km',
      name: 'Bioskop 4.5km',
      address: 'Jl. Sudirman',
      latitude: -6.2150,
      longitude: 106.8272,
      city: 'Jakarta',
    );

    final cinema15km = CinemaModel(
      id: 'c-15km',
      name: 'Bioskop 18km',
      address: 'Jl. Margonda',
      latitude: -6.3400,
      longitude: 106.8272,
      city: 'Depok',
    );

    test('getCinemasSortedByDistance with maxRadiusKm filters correctly', () {
      final service = CinemaService();
      final all = [cinema1km, cinema4km, cinema15km];

      // Radius 3 km: hanya cinema1km yang lolos
      final filtered3km = service.getCinemasSortedByDistance(
        all,
        userLat: userLat,
        userLng: userLng,
        maxRadiusKm: 3.0,
      );
      expect(filtered3km.length, equals(1));
      expect(filtered3km.first.id, equals('c-1km'));

      // Radius 5 km: cinema1km dan cinema4km lolos
      final filtered5km = service.getCinemasSortedByDistance(
        all,
        userLat: userLat,
        userLng: userLng,
        maxRadiusKm: 5.0,
      );
      expect(filtered5km.length, equals(2));

      // Radius null: semua bioskop lolos
      final filteredAll = service.getCinemasSortedByDistance(
        all,
        userLat: userLat,
        userLng: userLng,
        maxRadiusKm: null,
      );
      expect(filteredAll.length, equals(3));
    });
  });

  group('PB-046: Google Maps Navigation Route Integration Tests', () {
    test(
        'CinemaModel coordinates and URI parameters should be valid for external navigation',
        () {
      final cinema = CinemaModel(
        id: 'test-nav',
        name: 'Cinemate Grand Indonesia',
        address: 'Jl. M.H. Thamrin No. 1, Jakarta',
        latitude: -6.1950,
        longitude: 106.8200,
        city: 'Jakarta',
      );

      final navUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${cinema.latitude},${cinema.longitude}&destination_place_id=${Uri.encodeComponent(cinema.name)}&travelmode=driving',
      );

      expect(navUrl.scheme, equals('https'));
      expect(navUrl.host, equals('www.google.com'));
      expect(navUrl.queryParameters['destination'], equals('-6.195,106.82'));
      expect(navUrl.queryParameters['travelmode'], equals('driving'));
    });
  });
}
