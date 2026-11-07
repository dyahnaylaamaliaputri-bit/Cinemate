// lib/models/movie_model.dart
// Model data film dari TMDB API (PB-012)
// Referensi: SRS §3.1, PB-012

class MovieModel {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final List<int> genreIds;
  final double popularity;

  const MovieModel({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.genreIds,
    required this.popularity,
  });

  /// URL lengkap untuk poster film TMDB
  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) {
      return '';
    }
    if (posterPath!.startsWith('http')) return posterPath!;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// URL lengkap untuk backdrop / banner film TMDB
  String get backdropUrl {
    if (backdropPath == null || backdropPath!.isEmpty) {
      return posterUrl;
    }
    if (backdropPath!.startsWith('http')) return backdropPath!;
    return 'https://image.tmdb.org/t/p/w780$backdropPath';
  }

  /// Rating yang diformat 1 angka di belakang koma (misal: "8.5")
  String get formattedRating => voteAverage.toStringAsFixed(1);

  /// Tahun rilis (misal: "2024")
  String get releaseYear {
    if (releaseDate == null || releaseDate!.isEmpty) return '-';
    final parts = releaseDate!.split('-');
    return parts.isNotEmpty ? parts[0] : '-';
  }

  /// Durasi film (estimasi realistis bioskop: jam dan menit)
  String get formattedDuration {
    final mins = 100 + (id % 45); // antara 100 - 145 menit
    final hours = mins ~/ 60;
    final remainingMinutes = mins % 60;
    return '${hours}j ${remainingMinutes}m';
  }

  /// Nama genre berdasarkan TMDB Genre ID
  List<String> get genreNames {
    return genreIds
        .map((id) => _tmdbGenres[id])
        .whereType<String>()
        .take(3)
        .toList();
  }

  /// String genre gabungan (misal: "Action • Sci-Fi")
  String get genreString {
    final names = genreNames;
    return names.isNotEmpty ? names.join(' • ') : 'Bioskop';
  }

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? 'Untitled',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String? ?? json['first_air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'release_date': releaseDate,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'genre_ids': genreIds,
      'popularity': popularity,
    };
  }

  static const Map<int, String> _tmdbGenres = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };
}
