// lib/models/mood_model.dart
// Model untuk 6 Emosi / Suasana Hati dan Hasil Rekomendasi Film Mood AI (PB-031, PB-032, PB-033)

import 'package:flutter/material.dart';
import 'movie_model.dart';

enum MoodType {
  happy,
  sad,
  romantic,
  thrilled,
  chill,
  bored,
}

class MoodDefinition {
  final MoodType type;
  final String title;
  final String emoji;
  final String tagline;
  final String description;
  final List<Color> gradientColors;
  final List<int> genreIds; // TMDB genre IDs

  const MoodDefinition({
    required this.type,
    required this.title,
    required this.emoji,
    required this.tagline,
    required this.description,
    required this.gradientColors,
    required this.genreIds,
  });

  static const List<MoodDefinition> allMoods = [
    MoodDefinition(
      type: MoodType.happy,
      title: 'Gembira & Ceria',
      emoji: '😃',
      tagline: 'Tawa Lepas & Cerita Hangat',
      description:
          'Film komedi keluarga dan animasi penuh warna untuk mencerahkan harimu.',
      gradientColors: [Color(0xFFFF9900), Color(0xFFFF5E62)],
      genreIds: [35, 16, 10751], // Comedy, Animation, Family
    ),
    MoodDefinition(
      type: MoodType.sad,
      title: 'Haru & Menyentuh',
      emoji: '😢',
      tagline: 'Kisah Mendalam & Katarsis Emosi',
      description:
          'Film drama emosional dan kisah nyata inspiratif yang menggetarkan hati.',
      gradientColors: [Color(0xFF3A7BD5), Color(0xFF3A6073)],
      genreIds: [18], // Drama
    ),
    MoodDefinition(
      type: MoodType.romantic,
      title: 'Romantis & Baper',
      emoji: '❤️',
      tagline: 'Percintaan Manis & Hangat',
      description:
          'Kisah cinta manis, rom-com hangat, dan chemistry pasangan yang bikin senyum-senyum.',
      gradientColors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
      genreIds: [10749, 35], // Romance, Comedy
    ),
    MoodDefinition(
      type: MoodType.thrilled,
      title: 'Tegang & Adrenalin',
      emoji: '⚡',
      tagline: 'Aksi Meledak & Suspense Intens',
      description:
          'Laga tanpa henti, misteri kelam, dan sensasi mendebarkan yang memacu detak jantung.',
      gradientColors: [Color(0xFFE50914), Color(0xFF6B0F1A)],
      genreIds: [28, 27, 53], // Action, Horror, Thriller
    ),
    MoodDefinition(
      type: MoodType.chill,
      title: 'Santai & Rileks',
      emoji: '🧘',
      tagline: 'Petualangan Visual & Eksplorasi Imajinasi',
      description:
          'Pemandangan spektakuler, fiksi ilmiah menenangkan, dan dunia fantasi yang memukau.',
      gradientColors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      genreIds: [12, 878, 14], // Adventure, Sci-Fi, Fantasy
    ),
    MoodDefinition(
      type: MoodType.bored,
      title: 'Bosan & Butuh Kejutan',
      emoji: '🥱',
      tagline: 'Plot Twist Tak Terduga',
      description:
          'Misteri detektif dan alur cerita cerdas yang akan membuatmu terus menebak hingga akhir.',
      gradientColors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      genreIds: [9648, 80], // Mystery, Crime
    ),
  ];
}

class MoodRecommendationItem {
  final MovieModel movie;
  final int matchPercentage; // e.g. 98%
  final String aiReason;

  const MoodRecommendationItem({
    required this.movie,
    required this.matchPercentage,
    required this.aiReason,
  });
}
