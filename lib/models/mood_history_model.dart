// lib/models/mood_history_model.dart
// Model untuk riwayat hasil profiling Mood AI (PB-065)

class MoodHistoryItemModel {
  final int movieId;
  final String title;
  final String? posterPath;
  final int matchPercentage;
  final String? aiReason;

  const MoodHistoryItemModel({
    required this.movieId,
    required this.title,
    this.posterPath,
    required this.matchPercentage,
    this.aiReason,
  });

  Map<String, dynamic> toJson() => {
        'movie_id': movieId,
        'title': title,
        'poster_path': posterPath,
        'match_percentage': matchPercentage,
        'ai_reason': aiReason,
      };

  factory MoodHistoryItemModel.fromJson(Map<String, dynamic> json) =>
      MoodHistoryItemModel(
        movieId: (json['movie_id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? '',
        posterPath: json['poster_path']?.toString(),
        matchPercentage: (json['match_percentage'] as num?)?.toInt() ?? 90,
        aiReason: json['ai_reason']?.toString(),
      );
}

class MoodHistoryModel {
  final String id;
  final String moodType;
  final String moodTitle;
  final String moodEmoji;
  final DateTime timestamp;
  final List<MoodHistoryItemModel> movies;

  const MoodHistoryModel({
    required this.id,
    required this.moodType,
    required this.moodTitle,
    required this.moodEmoji,
    required this.timestamp,
    required this.movies,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mood_type': moodType,
        'mood_title': moodTitle,
        'mood_emoji': moodEmoji,
        'timestamp': timestamp.toIso8601String(),
        'movies': movies.map((m) => m.toJson()).toList(),
      };

  factory MoodHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawMovies = json['movies'] as List<dynamic>? ?? [];
    return MoodHistoryModel(
      id: json['id']?.toString() ?? '',
      moodType: json['mood_type']?.toString() ?? '',
      moodTitle: json['mood_title']?.toString() ?? '',
      moodEmoji: json['mood_emoji']?.toString() ?? '🎬',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      movies: rawMovies
          .map((m) =>
              MoodHistoryItemModel.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
    );
  }
}
