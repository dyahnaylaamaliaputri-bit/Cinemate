// test/cinema_model_test.dart
// Pengujian unit model CinemaModel dan kalkulasi jarak Haversine (PB-015)

import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/services/cinema_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => '.',
    );
  });

  group('CinemaModel & Haversine Distance Tests (PB-015)', () {
    test('CinemaModel fromJson should parse valid json properly', () {
      final json = {
        'id': 'cin-1',
        'name': 'Cinemate Plaza',
        'address': 'Jl. Sudirman No. 1, Jakarta Pusat',
        'latitude': -6.2088,
        'longitude': 106.8456,
        'city': 'Jakarta',
        'image_url': 'https://example.com/cinema.jpg',
      };

      final cinema = CinemaModel.fromJson(json);

      expect(cinema.id, 'cin-1');
      expect(cinema.name, 'Cinemate Plaza');
      expect(cinema.latitude, -6.2088);
      expect(cinema.longitude, 106.8456);
      expect(cinema.city, 'Jakarta');
      expect(cinema.imageUrl, 'https://example.com/cinema.jpg');
    });

    test(
        'calculateDistanceFrom should compute accurate distance in km using Haversine formula',
        () {
      final cinema = CinemaModel(
        id: '1',
        name: 'Metro Cinema Senayan',
        address: 'Jl. Asia Afrika No. 8',
        latitude: -6.2176,
        longitude: 106.8013,
      );

      // Posisi Jakarta Pusat: -6.2000, 106.8167
      final distance = cinema.calculateDistanceFrom(-6.2000, 106.8167);

      // Jarak terhitung sekitar 2.6 km (toleransi 0.5 km)
      expect(distance, greaterThan(2.0));
      expect(distance, lessThan(3.5));

      final cinemaWithDist = cinema.copyWith(distanceKm: distance);
      expect(cinemaWithDist.formattedDistance, contains('km'));
    });

    test(
        'getNearestCinemas should sort by distance ascending and return top 3 cinemas',
        () {
      final service = CinemaService();

      final cinemas = [
        const CinemaModel(
          id: '1',
          name: 'Cinemate Plaza',
          address: 'Jl. Sudirman No. 1',
          latitude: -6.2088,
          longitude: 106.8456,
        ),
        const CinemaModel(
          id: '2',
          name: 'Nusantara XXI Fiktif',
          address: 'Jl. Gatot Subroto No. 25',
          latitude: -6.2297,
          longitude: 106.8295,
        ),
        const CinemaModel(
          id: '3',
          name: 'Metro Cinema Senayan',
          address: 'Jl. Asia Afrika No. 8',
          latitude: -6.2176,
          longitude: 106.8013,
        ),
        const CinemaModel(
          id: '4',
          name: 'Cinemate Kelapa Gading',
          address: 'Jl. Boulevard Raya',
          latitude: -6.1601,
          longitude: 106.9013,
        ),
        const CinemaModel(
          id: '5',
          name: 'Bintang Cinema Depok',
          address: 'Jl. Margonda Raya No. 50',
          latitude: -6.3728,
          longitude: 106.8318,
        ),
      ];

      // Lokasi user di Senayan: -6.2176, 106.8013
      final nearest = service.getNearestCinemas(
        cinemas,
        userLat: -6.2176,
        userLng: 106.8013,
        limit: 3,
      );

      expect(nearest.length, 3);
      // Peringkat 1 harus Metro Cinema Senayan (jarak 0 km)
      expect(nearest[0].name, 'Metro Cinema Senayan');
      expect(nearest[0].distanceKm, lessThan(0.01));

      // Jarak bioskop berikutnya harus lebih jauh atau sama
      expect(
          nearest[1].distanceKm!, greaterThanOrEqualTo(nearest[0].distanceKm!));
      expect(
          nearest[2].distanceKm!, greaterThanOrEqualTo(nearest[1].distanceKm!));

      // Depok dan Kelapa Gading tidak boleh masuk top 3 karena lebih jauh
      final names = nearest.map((c) => c.name).toList();
      expect(names.contains('Bintang Cinema Depok'), isFalse);
    });

    test(
        'getNearestCinemas when in Depok should prioritize Bintang Cinema Depok as #1',
        () {
      final service = CinemaService();

      final cinemas = [
        const CinemaModel(
          id: '1',
          name: 'Cinemate Plaza',
          address: 'Jl. Sudirman No. 1',
          latitude: -6.2088,
          longitude: 106.8456,
        ),
        const CinemaModel(
          id: '5',
          name: 'Bintang Cinema Depok',
          address: 'Jl. Margonda Raya No. 50',
          latitude: -6.3728,
          longitude: 106.8318,
        ),
      ];

      final nearest = service.getNearestCinemas(
        cinemas,
        userLat: -6.3728,
        userLng: 106.8318,
        limit: 1,
      );

      expect(nearest.first.name, 'Bintang Cinema Depok');
      expect(nearest.first.distanceKm, lessThan(0.01));
    });
  });
}
