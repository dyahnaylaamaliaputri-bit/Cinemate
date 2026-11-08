// test/mood_recommendation_test.dart
// Unit tests untuk modul Rekomendasi Film Berbasis Mood AI (PB-031, PB-032, PB-033)

import 'package:flutter_test/flutter_test.dart';
import 'package:cinemate/models/mood_model.dart';
import 'package:cinemate/services/mood_service.dart';

void main() {
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
        'getRecommendations should return recommendations with AI match and personal reasoning',
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
  });
}
