// test/mood_recommendation_test.dart
// Unit tests untuk modul Rekomendasi Film Berbasis Mood AI (PB-031, PB-032, PB-033)
// Menguji MoodDefinition, MoodController, MoodRecommendationService (Offline Fallback & Hive Cache)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/controllers/mood_controller.dart';
import 'package:cinemate/models/mood_model.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/services/mood_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => tempDir.path,
    );
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('MoodDefinition Model Tests (PB-031)', () {
    test('allMoods should contain exactly 6 distinct moods', () {
      final moods = MoodDefinition.allMoods;
      expect(moods.length, equals(6));

      final types = moods.map((m) => m.type).toSet();
      expect(
        types,
        containsAll([
          MoodType.happy,
          MoodType.sad,
          MoodType.romantic,
          MoodType.thrilled,
          MoodType.chill,
          MoodType.bored,
        ]),
      );
    });

    test(
        'Each mood should have emojis, gradients, and valid TMDB genre mapping',
        () {
      for (final mood in MoodDefinition.allMoods) {
        expect(mood.emoji, isNotEmpty);
        expect(mood.title, isNotEmpty);
        expect(mood.gradientColors.length, greaterThanOrEqualTo(2));
        expect(mood.genreIds, isNotEmpty);
      }
    });

    test('Happy mood maps to Comedy & Animation genre IDs', () {
      final happy =
          MoodDefinition.allMoods.firstWhere((m) => m.type == MoodType.happy);
      expect(happy.genreIds, contains(35)); // Comedy
      expect(happy.genreIds, contains(16)); // Animation
    });

    test('Thrilled mood maps to Action, Horror, or Thriller genre IDs', () {
      final thrilled = MoodDefinition.allMoods
          .firstWhere((m) => m.type == MoodType.thrilled);
      expect(
          thrilled.genreIds, anyOf(contains(28), contains(27), contains(53)));
    });
  });

  group('MoodRecommendationService Tests (PB-032, PB-033)', () {
    late MoodRecommendationService service;

    setUp(() {
      service = MoodRecommendationService();
    });

    test(
        'getRecommendations should return recommendations with AI match and personal reasoning without Supabase',
        () async {
      final results = await service.getRecommendations(MoodType.happy);

      expect(results, isNotEmpty);
      for (final rec in results) {
        // PB-033: Persentase kecocokan AI tinggi (88% - 99%)
        expect(rec.matchPercentage, greaterThanOrEqualTo(88));
        expect(rec.matchPercentage, lessThanOrEqualTo(99));

        // PB-033: Alasan personal berbasis AI
        expect(rec.aiReason, isNotEmpty);
        expect(rec.aiReason, contains(rec.movie.title));

        // Film harus valid
        expect(rec.movie.title, isNotEmpty);
        expect(rec.movie.voteAverage, greaterThanOrEqualTo(7.0));
      }
    });

    test(
        'Recommendations for Romance mood include love and chemistry reasoning',
        () async {
      final results = await service.getRecommendations(MoodType.romantic);

      expect(results, isNotEmpty);
      final firstRec = results.first;
      expect(
          firstRec.aiReason.toLowerCase(),
          anyOf(
              contains('cinta'), contains('romantis'), contains('chemistry')));
    });

    test(
        'Recommendations for Thrilled mood include adrenaline and tension reasoning',
        () async {
      final results = await service.getRecommendations(MoodType.thrilled);

      expect(results, isNotEmpty);
      final firstRec = results.first;
      expect(firstRec.aiReason.toLowerCase(),
          anyOf(contains('adrenalin'), contains('tegang'), contains('aksi')));
    });

    test('All 6 moods produce valid curated recommendations', () async {
      for (final mood in MoodDefinition.allMoods) {
        final results = await service.getRecommendations(mood.type);
        expect(results, isNotEmpty,
            reason: 'Mood ${mood.title} harus punya rekomendasi');
        expect(results.first.matchPercentage, inInclusiveRange(88, 99));
        expect(results.first.aiReason, isNotEmpty);
      }
    });
  });

  group('MoodController Reactive State Tests (PB-031)', () {
    test('MoodController initializes with 6 moods and loads default happy mood',
        () async {
      Get.testMode = true;
      final controller = MoodController();
      expect(controller.allMoods.length, equals(6));
      expect(controller.selectedMood.value.type, equals(MoodType.happy));

      await controller.loadRecommendations();
      expect(controller.recommendations.isNotEmpty, isTrue);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isEmpty);
    });

    test('MoodController selectMood updates selected mood and reloads list',
        () async {
      Get.testMode = true;
      final controller = MoodController();

      final sadMood =
          MoodDefinition.allMoods.firstWhere((m) => m.type == MoodType.sad);
      await controller.selectMood(sadMood);

      expect(controller.selectedMood.value.type, equals(MoodType.sad));
      expect(controller.recommendations.isNotEmpty, isTrue);
      expect(
          controller.recommendations.first.aiReason.toLowerCase(),
          anyOf(contains('karakter'), contains('emosional'),
              contains('katarsis')));

      // Ganti ke bored
      final boredMood =
          MoodDefinition.allMoods.firstWhere((m) => m.type == MoodType.bored);
      await controller.selectMood(boredMood);

      expect(controller.selectedMood.value.type, equals(MoodType.bored));
      expect(controller.recommendations.first.aiReason.toLowerCase(),
          anyOf(contains('twist'), contains('teka-teki'), contains('bosan')));
    });

    test('Selecting the already active mood does not trigger duplicate load',
        () async {
      Get.testMode = true;
      final controller = MoodController();
      await controller.loadRecommendations();

      final currentCount = controller.recommendations.length;
      final currentMood = controller.selectedMood.value;

      // Memanggil kembali mood yang sama
      await controller.selectMood(currentMood);
      expect(controller.recommendations.length, equals(currentCount));
    });

    test('MoodController setSortBy updates sorting parameter (PB-032)',
        () async {
      Get.testMode = true;
      final controller = MoodController();
      expect(controller.selectedSortBy.value, equals('popularity.desc'));

      controller.setSortBy('vote_average.desc');
      expect(controller.selectedSortBy.value, equals('vote_average.desc'));
    });
  });

  group('PB-033: AI Match & Direct Booking Action Tests', () {
    test('bookMovie and viewMovieDetail direct navigation methods', () async {
      Get.testMode = true;
      final controller = MoodController();
      const movie = MovieModel(
        id: 1022789,
        title: 'Inside Out 2',
        overview: 'Riley beranjak remaja.',
        voteAverage: 8.0,
        voteCount: 3000,
        popularity: 150.0,
        genreIds: [16, 35, 10751],
      );

      // Verifikasi metode bookMovie dan viewMovieDetail dapat dieksekusi tanpa error
      expect(() => controller.bookMovie(movie), returnsNormally);
      expect(() => controller.viewMovieDetail(movie), returnsNormally);
    });

    test('AI match percentage is always within high confidence range 88%-99%',
        () async {
      final service = MoodRecommendationService();
      final results = await service.getRecommendations(MoodType.happy);

      for (final rec in results) {
        expect(rec.matchPercentage, greaterThanOrEqualTo(88));
        expect(rec.matchPercentage, lessThanOrEqualTo(99));
        expect(rec.aiReason, contains(rec.movie.title));
      }
    });
  });
}
