// lib/services/movie_service.dart
// Service untuk memanggil API katalog film TMDB (The Movie Database) (PB-012)
// Referensi: SRS §3.1, PB-012

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie_model.dart';
import 'http_service.dart';

class MovieService {
  MovieService._internal();
  static final MovieService _instance = MovieService._internal();
  factory MovieService() => _instance;

  final HttpService _http = HttpService();

  String get _baseUrl =>
      dotenv.env['TMDB_BASE_URL'] ?? 'https://api.themoviedb.org/3';

  String? get _apiKey {
    final key = dotenv.env['TMDB_API_KEY'];
    if (key == null || key.isEmpty || key == 'YOUR_TMDB_API_KEY_HERE') {
      return null;
    }
    return key;
  }

  /// Mengambil daftar film yang sedang tayang (Now Playing)
  Future<List<MovieModel>> getNowPlaying({int page = 1}) async {
    final key = _apiKey;
    if (key == null) {
      debugPrint('[MovieService] TMDB API key tidak ditemukan, memuat data mock Now Playing');
      return _mockNowPlaying;
    }

    try {
      final response = await _http.get(
        '$_baseUrl/movie/now_playing',
        queryParameters: {
          'api_key': key,
          'language': 'id-ID',
          'page': page,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $key'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List results = response.data['results'] ?? [];
        return results.map((e) => MovieModel.fromJson(e)).toList();
      }
      return _mockNowPlaying;
    } catch (e) {
      debugPrint('[MovieService] Gagal memuat Now Playing ($e), memuat mock data');
      return _mockNowPlaying;
    }
  }

  /// Mengambil daftar film yang akan segera tayang (Coming Soon / Upcoming)
  Future<List<MovieModel>> getUpcoming({int page = 1}) async {
    final key = _apiKey;
    if (key == null) {
      debugPrint('[MovieService] TMDB API key tidak ditemukan, memuat data mock Upcoming');
      return _mockUpcoming;
    }

    try {
      final response = await _http.get(
        '$_baseUrl/movie/upcoming',
        queryParameters: {
          'api_key': key,
          'language': 'id-ID',
          'page': page,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $key'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List results = response.data['results'] ?? [];
        return results.map((e) => MovieModel.fromJson(e)).toList();
      }
      return _mockUpcoming;
    } catch (e) {
      debugPrint('[MovieService] Gagal memuat Upcoming ($e), memuat mock data');
      return _mockUpcoming;
    }
  }

  /// Mengambil film sorotan untuk banner carousel utama
  Future<List<MovieModel>> getBannerMovies() async {
    final nowPlaying = await getNowPlaying();
    if (nowPlaying.isNotEmpty) {
      // Ambil 5 film berating/popularitas tertinggi untuk carousel
      final sorted = List<MovieModel>.from(nowPlaying)
        ..sort((a, b) => b.popularity.compareTo(a.popularity));
      return sorted.take(5).toList();
    }
    return _mockNowPlaying.take(5).toList();
  }

  // =========================================================================
  // MOCK DATA (Fallback andal jika TMDB API Key belum dimasukkan)
  // Poster & Backdrop path valid dari CDN resmi TMDB
  // =========================================================================

  static final List<MovieModel> _mockNowPlaying = [
    const MovieModel(
      id: 693134,
      title: 'Dune: Part Two',
      overview: 'Paul Atreides bersatu dengan Chani dan Fremen untuk membalas dendam terhadap para konspirator yang menghancurkan keluarganya.',
      posterPath: '/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
      backdropPath: '/xOMo8BRK7PfcJv9JCnx7s5200bm.jpg',
      releaseDate: '2024-03-01',
      voteAverage: 8.3,
      voteCount: 4500,
      genreIds: [878, 12],
      popularity: 350.5,
    ),
    const MovieModel(
      id: 533535,
      title: 'Deadpool & Wolverine',
      overview: 'Wade Wilson yang lesu kembali beraksi saat TVA merekrutnya untuk melindungi garis waktu bersama Wolverine yang enggan.',
      posterPath: '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      backdropPath: '/yDHYTjA3R0jFYba16jBB1jv8v2C.jpg',
      releaseDate: '2024-07-26',
      voteAverage: 7.9,
      voteCount: 3800,
      genreIds: [28, 35, 878],
      popularity: 420.2,
    ),
    const MovieModel(
      id: 1022789,
      title: 'Inside Out 2',
      overview: 'Riley kini beranjak remaja dan Ruang Kendali emosinya mengalami perombakan mendadak untuk menyambut emosi-emosi baru.',
      posterPath: '/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
      backdropPath: '/p5ozvmdgsmbWe0H8wf4NelljhBs.jpg',
      releaseDate: '2024-06-14',
      voteAverage: 8.0,
      voteCount: 5200,
      genreIds: [16, 10751, 35],
      popularity: 380.1,
    ),
    const MovieModel(
      id: 519182,
      title: 'Despicable Me 4',
      overview: 'Gru menghadapi musuh baru Maxime Le Mal dan pacarnya Valentina, memaksa seluruh keluarga Gru untuk melarikan diri.',
      posterPath: '/wWba3TaojhK7NdycRhoQpsG0FaH.jpg',
      backdropPath: '/lgkGYSyJsGtz6q7OpeaGTUhHbAc.jpg',
      releaseDate: '2024-07-03',
      voteAverage: 7.3,
      voteCount: 2200,
      genreIds: [16, 10751, 35],
      popularity: 290.0,
    ),
    const MovieModel(
      id: 573435,
      title: 'Bad Boys: Ride or Die',
      overview: 'Detektif Mike Lowrey dan Marcus Burnett kembali beraksi saat kapten mereka difitnah, membuat mereka menjadi buronan.',
      posterPath: '/nP6RliHjxsz4irTKsxe8FRhKZYl.jpg',
      backdropPath: '/ga4OLm4qLxO1GyF4hk00V98G9QG.jpg',
      releaseDate: '2024-06-07',
      voteAverage: 7.6,
      voteCount: 2100,
      genreIds: [28, 80, 35],
      popularity: 260.4,
    ),
  ];

  static final List<MovieModel> _mockUpcoming = [
    const MovieModel(
      id: 558449,
      title: 'Gladiator II',
      overview: 'Bertahun-tahun setelah menyaksikan kematian Maximus di tangan pamannya, Lucius harus memasuki Colosseum untuk memperjuangkan masa depan Roma.',
      posterPath: '/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
      backdropPath: '/euYIwmwkmz95mnEx7vBM0MqzEDn.jpg',
      releaseDate: '2024-11-22',
      voteAverage: 8.1,
      voteCount: 890,
      genreIds: [28, 12, 18],
      popularity: 310.0,
    ),
    const MovieModel(
      id: 402431,
      title: 'Wicked',
      overview: 'Kisah Elphaba, wanita muda berkulit hijau yang disalahpahami, dan Glinda, wanita populer penuh keistimewaan di Negeri Oz.',
      posterPath: '/dfa6kK3yP1N99WfJ7eX85L5m89q.jpg',
      backdropPath: '/uKB22E5kyQE9wf4GEZe9oMcflvg.jpg',
      releaseDate: '2024-11-27',
      voteAverage: 7.7,
      voteCount: 650,
      genreIds: [18, 14, 10402],
      popularity: 280.0,
    ),
    const MovieModel(
      id: 1241982,
      title: 'Moana 2',
      overview: 'Moana menerima panggilan mendadak dari leluhurnya untuk berlayar ke perairan jauh Oseania dalam petualangan berbahaya.',
      posterPath: '/4YZpsylmjHbqeWzjKpUEF8gcLUV.jpg',
      backdropPath: '/tElnmtQ6yz1PjN1kePNl8yMSb59.jpg',
      releaseDate: '2024-11-27',
      voteAverage: 7.8,
      voteCount: 710,
      genreIds: [16, 12, 10751],
      popularity: 330.0,
    ),
    const MovieModel(
      id: 933260,
      title: 'The Substance',
      overview: 'Seorang selebritas yang menua memutuskan untuk menggunakan obat pasar gelap misterius yang dapat mereplikasi sel untuk menciptakan versi dirinya yang lebih muda.',
      posterPath: '/lqoMzCcZY59p0k8j3zIic3c0nS7.jpg',
      backdropPath: '/7h6r9WcQ3pZ1G9B3dZ2W4x5z8a9.jpg',
      releaseDate: '2024-10-31',
      voteAverage: 7.4,
      voteCount: 1400,
      genreIds: [27, 878, 18],
      popularity: 240.0,
    ),
  ];
}
