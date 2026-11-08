// test/booking_cinema_test.dart
// Pengujian unit alur pemesanan Booked by Cinema (PB-018)

import 'dart:io';
import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/models/showtime_model.dart';
import 'package:cinemate/services/showtime_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => tempDir.path,
    );
  });

  group('ShowtimeModel & Booked by Cinema Tests (PB-018)', () {
    test('ShowtimeModel should deserialize json and format price correctly',
        () {
      final json = {
        'id': 'st-1',
        'cinema_id': 'cin-1',
        'movie_id': 1022789,
        'movie_title': 'Inside Out 2',
        'show_date': '2026-11-07',
        'show_time': '14:00',
        'hall_name': 'Studio 1',
        'experience': 'Regular 2D',
        'price': 50000,
        'total_seats': 100,
        'available_seats': 85,
      };

      final showtime = ShowtimeModel.fromJson(json);

      expect(showtime.id, 'st-1');
      expect(showtime.movieTitle, 'Inside Out 2');
      expect(showtime.price, 50000);
      expect(showtime.formattedPrice, 'Rp 50.000');
      expect(showtime.showTime, '14:00');
      expect(showtime.experience, 'Regular 2D');
    });

    test(
        'ShowtimeService should return multi-studio showtimes (Regular, IMAX, Premiere)',
        () async {
      final service = ShowtimeService();

      final showtimes = await service.getShowtimes(
        cinemaId: 'cin-1',
        date: '2026-11-07',
        movieId: 533535,
        movieTitle: 'Deadpool & Wolverine',
      );

      expect(showtimes, isNotEmpty);

      // Pastikan ada studio Regular 2D, IMAX, dan Premiere
      final experiences = showtimes.map((s) => s.experience).toSet();
      expect(experiences.contains('Regular 2D'), isTrue);
      expect(experiences.contains('IMAX with Laser'), isTrue);
      expect(experiences.contains('The Premiere'), isTrue);

      // Verifikasi harga studio
      final regular = showtimes.firstWhere((s) => s.experience == 'Regular 2D');
      final imax =
          showtimes.firstWhere((s) => s.experience == 'IMAX with Laser');
      final premiere =
          showtimes.firstWhere((s) => s.experience == 'The Premiere');

      expect(regular.price, 50000);
      expect(imax.price, 75000);
      expect(premiere.price, 100000);
    });

    test('CinemaModel and MovieModel should integrate with booking showtimes',
        () {
      const cinema = CinemaModel(
        id: 'cin-senayan',
        name: 'Metro Cinema Senayan',
        address: 'Jl. Asia Afrika No. 8',
        latitude: -6.2176,
        longitude: 106.8013,
      );

      final movie = MovieModel(
        id: 533535,
        title: 'Deadpool & Wolverine',
        overview: 'Action movie',
        posterPath: '/path.jpg',
        backdropPath: '/bg.jpg',
        voteAverage: 7.9,
        voteCount: 1200,
        popularity: 250.0,
        releaseDate: '2024-07-24',
        genreIds: [28, 35],
      );

      expect(cinema.name, 'Metro Cinema Senayan');
      expect(movie.title, 'Deadpool & Wolverine');
    });

    test(
        'ShowtimeService getCinemasForMovie should return cinemas sorted by proximity (PB-019)',
        () async {
      final service = ShowtimeService();

      final cinemas = await service.getCinemasForMovie(
        533535,
        userLat: -6.2176,
        userLng: 106.8013,
      );

      expect(cinemas, isNotEmpty);
      // Metro Cinema Senayan harus yang terdekat (0 km)
      expect(cinemas.first.name, 'Metro Cinema Senayan');
      expect(cinemas.first.distanceKm, lessThan(0.01));
    });
  });
}
