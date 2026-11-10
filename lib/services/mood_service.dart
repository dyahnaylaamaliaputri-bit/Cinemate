// lib/services/mood_service.dart
// Service untuk discovery film TMDB berbasis emosi dan AI reasoning (PB-031, PB-032, PB-033)
// Mendukung offline-first caching dengan Hive dan kurasi lokal tanpa Supabase.

import 'dart:math';
import '../models/mood_model.dart';
import '../models/movie_model.dart';
import 'http_service.dart';
import 'storage_service.dart';

class MoodRecommendationService {
  MoodRecommendationService._internal();
  static final MoodRecommendationService _instance =
      MoodRecommendationService._internal();
  factory MoodRecommendationService() => _instance;

  final HttpService _http = HttpService();
  final StorageService _storage = StorageService();

  /// Mengambil rekomendasi film berdasarkan mood pengguna (PB-032)
  /// Mendukung cache Hive lokal dan fallback kurasi offline tanpa Supabase.
  Future<List<MoodRecommendationItem>> getRecommendations(
    MoodType moodType, {
    bool forceRefresh = false,
  }) async {
    final moodDef =
        MoodDefinition.allMoods.firstWhere((m) => m.type == moodType);
    final genresParam = moodDef.genreIds.join(',');
    final cacheKey = 'mood_${moodType.name}';

    // 1. Cek cache Hive terlebih dahulu jika tidak force refresh
    if (!forceRefresh) {
      try {
        final cached = await _storage.getCachedMovies(cacheKey);
        if (cached.data != null &&
            cached.data!.isNotEmpty &&
            !cached.isExpired) {
          final movies = cached.data!.map(MovieModel.fromJson).toList();
          return _generateMoodRecommendations(moodDef, movies);
        }
      } catch (e) {
        debugPrint('[MoodService] Hive cache read warning: $e');
      }
    }

    // 2. Coba fetch online dari TMDB API
    try {
      final response = await _http.get(
        'https://api.themoviedb.org/3/discover/movie',
        queryParameters: {
          'with_genres': genresParam,
          'sort_by': 'popularity.desc',
          'vote_average.gte': 7.0,
          'include_adult': false,
          'page': 1,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List results = response.data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          final rawMovies = results
              .take(6)
              .map((raw) => raw as Map<String, dynamic>)
              .toList();

          // Simpan ke Hive cache lokal
          try {
            await _storage.cacheMovies(cacheKey, rawMovies);
          } catch (_) {}

          final movies = rawMovies.map(MovieModel.fromJson).toList();
          return _generateMoodRecommendations(moodDef, movies);
        }
      }
    } catch (e) {
      debugPrint(
          '[MoodService] TMDB discover fetch error (checking cached or curated fallback): $e');
    }

    // 3. Fallback jika offline: coba cache Hive yang expired sekalipun
    try {
      final cached = await _storage.getCachedMovies(cacheKey);
      if (cached.data != null && cached.data!.isNotEmpty) {
        final movies = cached.data!.map(MovieModel.fromJson).toList();
        return _generateMoodRecommendations(moodDef, movies);
      }
    } catch (_) {}

    // 4. Fallback kurasi offline jika API TMDB offline / limit dan belum ada cache
    final fallbackMovies = _getCuratedFallbackMovies(moodType);
    return _generateMoodRecommendations(moodDef, fallbackMovies);
  }

  /// Membungkus film dengan persentase kecocokan AI dan alasan personal (PB-033)
  List<MoodRecommendationItem> _generateMoodRecommendations(
    MoodDefinition moodDef,
    List<MovieModel> movies,
  ) {
    final rnd = Random(moodDef.type.index + 42); // Seed konsisten per mood
    final List<MoodRecommendationItem> list = [];

    for (int i = 0; i < movies.length; i++) {
      final movie = movies[i];
      // Persentase kecocokan antara 92% - 99%
      final match = 99 - (i * 2) - rnd.nextInt(2);
      final reason =
          _generateAiReason(moodDef.type, movie.title, movie.voteAverage);

      list.add(MoodRecommendationItem(
        movie: movie,
        matchPercentage: match.clamp(88, 99),
        aiReason: reason,
      ));
    }

    return list;
  }

  String _generateAiReason(MoodType mood, String title, double rating) {
    switch (mood) {
      case MoodType.happy:
        return 'Dengan rating $rating★, alur cerita yang ceria dan humor segar dalam "$title" terbukti ampuh membangkitkan senyum dan mood positifmu.';
      case MoodType.sad:
        return 'Penghayatan karakter mendalam dan narasi emosional dalam "$title" ($rating★) memberikan ruang katarsis yang pas untuk melepaskan beban perasaanmu.';
      case MoodType.romantic:
        return 'Chemistry manis dan dialog romantis yang menyentuh dalam "$title" akan membuat suasana hatimu terasa hangat dan penuh cinta.';
      case MoodType.thrilled:
        return 'Ketegangan intens dan aksi beradrenalin tinggi dengan tempo cepat di "$title" ($rating★) dijamin membuatmu terpaku di kursi bioskop.';
      case MoodType.chill:
        return 'Visual sinematik memukau dan scoring musik yang menenangkan dalam "$title" sangat sempurna untuk melepas penat dan rileks sejenak.';
      case MoodType.bored:
        return 'Plot twist tak terduga dan teka-teki cerdas dalam "$title" akan menantang intuisimu dan seketika mengusir rasa bosan.';
    }
  }

  /// Koleksi film kurasi offline berkualitas tinggi per mood
  List<MovieModel> _getCuratedFallbackMovies(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return const [
          MovieModel(
            id: 1022789,
            title: 'Inside Out 2',
            overview:
                'Kembali ke dalam pikiran remaja Riley saat kantor emosi mengalami renovasi tak terduga untuk memberi ruang bagi sesuatu yang sama sekali tidak diduga: Emosi Baru!',
            posterPath: '/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
            backdropPath: '/xg27NrXi7VXCGUr7MG75UqLl6Vg.jpg',
            voteAverage: 7.6,
            voteCount: 3800,
            popularity: 110.5,
            releaseDate: '2024-06-11',
            genreIds: [16, 35, 10751],
          ),
          MovieModel(
            id: 519182,
            title: 'Despicable Me 4',
            overview:
                'Gru, Lucy dan putri-putri mereka menyambut anggota baru keluarga, Gru Jr., yang berniat menyiksa ayahnya dalam petualangan kocak.',
            posterPath: '/wWba3TaojhK7NdycRhoQpsG0FaH.jpg',
            backdropPath: '/lgkFt6ydDAg7BymaGoktK7Fl7io.jpg',
            voteAverage: 7.1,
            voteCount: 2100,
            popularity: 95.0,
            releaseDate: '2024-06-20',
            genreIds: [16, 10751, 35],
          ),
          MovieModel(
            id: 354912,
            title: 'Coco',
            overview:
                'Meskipun keluarganya melarang musik, Miguel bermimpi menjadi musisi berprestasi dan berpetualang ke Negeri Orang Mati yang memukau.',
            posterPath: '/gGEsBPAijhVUFoiNpgZXqRVWJt2.jpg',
            backdropPath: '/askg3SMvhqEl4OL52YuvdtQw40Y.jpg',
            voteAverage: 8.2,
            voteCount: 18500,
            popularity: 88.0,
            releaseDate: '2017-10-27',
            genreIds: [10751, 16, 35],
          ),
        ];

      case MoodType.sad:
        return const [
          MovieModel(
            id: 872585,
            title: 'Oppenheimer',
            overview:
                'Kisah fisikawan J. Robert Oppenheimer yang memimpin Proyek Manhattan untuk mengembangkan bom atom pertama di dunia dan pergulatan moralnya.',
            posterPath: '/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
            backdropPath: '/rLb2cw69zbPQNsuyFukY0ivDr7r.jpg',
            voteAverage: 8.1,
            voteCount: 9200,
            popularity: 92.0,
            releaseDate: '2023-07-19',
            genreIds: [18, 36],
          ),
          MovieModel(
            id: 666277,
            title: 'Past Lives',
            overview:
                'Nora dan Hae Sung, dua teman masa kecil yang terpisah setelah keluarga Nora beremigrasi dari Korea Selatan, dipertemukan kembali di New York.',
            posterPath: '/k3waqVXSnvCZWfJYNtdamTgTtTA.jpg',
            backdropPath: '/g4T5g9z139Pfqo5E6GZ6p737iQc.jpg',
            voteAverage: 7.9,
            voteCount: 1600,
            popularity: 70.0,
            releaseDate: '2023-06-02',
            genreIds: [18, 10749],
          ),
        ];

      case MoodType.romantic:
        return const [
          MovieModel(
            id: 1072790,
            title: 'Anyone But You',
            overview:
                'Setelah kencan pertama yang luar biasa, ketertarikan Bea dan Ben berubah menjadi dingin—hingga mereka tiba-tiba bertemu lagi di pernikahan di Australia.',
            posterPath: '/yRt7MGBElABCxm1ulFS49N2qj9e.jpg',
            backdropPath: '/jXJxMcVoTTGzgDBfOuuG7Zz470m.jpg',
            voteAverage: 7.0,
            voteCount: 1950,
            popularity: 82.0,
            releaseDate: '2023-12-21',
            genreIds: [35, 10749],
          ),
          MovieModel(
            id: 313369,
            title: 'La La Land',
            overview:
                'Di Los Angeles, Mia seorang aktris yang bercita-cita tinggi dan Sebastian seorang musisi jazz berdedikasi berjuang meraih mimpi sambil merajut cinta.',
            posterPath: '/uDO8zWDhfWwoFdKS4fzkVJt0Rf0.jpg',
            backdropPath: '/qJeU7KMh42p6p30Dk75F2w17r7j.jpg',
            voteAverage: 7.9,
            voteCount: 16200,
            popularity: 89.0,
            releaseDate: '2016-11-29',
            genreIds: [35, 18, 10749],
          ),
        ];

      case MoodType.thrilled:
        return const [
          MovieModel(
            id: 533535,
            title: 'Deadpool & Wolverine',
            overview:
                'Deadpool yang santai ditugaskan dalam misi penyelamatan multisemesta bersama Wolverine yang enggan dan sinis dalam pertarungan brutal yang epik.',
            posterPath: '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
            backdropPath: '/yDHYTfA3R0jFYba16jBB1jv82EU.jpg',
            voteAverage: 7.7,
            voteCount: 5400,
            popularity: 140.0,
            releaseDate: '2024-07-24',
            genreIds: [28, 35, 878],
          ),
          MovieModel(
            id: 945961,
            title: 'Alien: Romulus',
            overview:
                'Sekelompok pemuda pemulung luar angkasa berhadapan langsung dengan bentuk kehidupan paling mengerikan di alam semesta saat menjelajahi stasiun terbengkalai.',
            posterPath: '/b33nnKl1vvg6MfFc6FcfmRpuaY9.jpg',
            backdropPath: '/9SSEUrSqhljBMzRe4aBTh17rUaC.jpg',
            voteAverage: 7.3,
            voteCount: 2200,
            popularity: 105.0,
            releaseDate: '2024-08-13',
            genreIds: [27, 878, 53],
          ),
        ];

      case MoodType.chill:
        return const [
          MovieModel(
            id: 693134,
            title: 'Dune: Part Two',
            overview:
                'Paul Atreides bersatu dengan Chani dan Fremen untuk membalas dendam terhadap para konspirator yang menghancurkan keluarganya di gurun Arrakis.',
            posterPath: '/czembW0Rk1Ke7lCJGhkAi0ym92H.jpg',
            backdropPath: '/xOMo8BRK7PfcJv9JCnx7s520fff.jpg',
            voteAverage: 8.2,
            voteCount: 5100,
            popularity: 115.0,
            releaseDate: '2024-02-27',
            genreIds: [878, 12],
          ),
          MovieModel(
            id: 157336,
            title: 'Interstellar',
            overview:
                'Petualangan melintasi lubang cacing di luar angkasa dalam upaya memastikan kelangsungan hidup umat manusia di tengah bumi yang sekarat.',
            posterPath: '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
            backdropPath: '/xJHokMbljvjADYdit5fK5VQsXEG.jpg',
            voteAverage: 8.4,
            voteCount: 34500,
            popularity: 98.0,
            releaseDate: '2014-11-05',
            genreIds: [12, 18, 878],
          ),
        ];

      case MoodType.bored:
        return const [
          MovieModel(
            id: 546554,
            title: 'Knives Out',
            overview:
                'Ketika novelis kriminal kaya Harlan Thrombey ditemukan tewas di tanah miliknya, Detektif Benoit Blanc yang misterius dipanggil untuk menyelidiki.',
            posterPath: '/pThyQovXQrw2m0s9x82twj48Jq4.jpg',
            backdropPath: '/4HWAQu28e2yaWrtupFPGFkdNU7V.jpg',
            voteAverage: 7.9,
            voteCount: 11800,
            popularity: 76.0,
            releaseDate: '2019-11-27',
            genreIds: [35, 80, 9648],
          ),
          MovieModel(
            id: 6661374,
            title: 'Glass Onion: A Knives Out Mystery',
            overview:
                'Miliarder teknologi Miles Bron mengundang teman-temannya ke pulau pribadinya di Yunani untuk permainan pesta misteri pembunuhan.',
            posterPath: '/vDGr1YdrlfbU9wxTOdpf3zChmv9.jpg',
            backdropPath: '/dKqa850uvbNSCaQCV4Im1XlzEtQ.jpg',
            voteAverage: 7.1,
            voteCount: 5050,
            popularity: 68.0,
            releaseDate: '2022-11-23',
            genreIds: [35, 80, 9648],
          ),
        ];
    }
  }
}
