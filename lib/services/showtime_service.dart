// lib/services/showtime_service.dart
// Service untuk jadwal tayang bioskop (Showtimes) & integrasi Supabase (PB-018)

import 'package:flutter/foundation.dart';
import '../models/movie_model.dart';
import '../models/showtime_model.dart';
import 'movie_service.dart';
import 'supabase_service.dart';

class ShowtimeService {
  ShowtimeService._internal();
  static final ShowtimeService _instance = ShowtimeService._internal();
  factory ShowtimeService() => _instance;

  final SupabaseService _supabase = SupabaseService();
  final MovieService _movieService = MovieService();

  /// Mengambil daftar film yang sedang tayang di bioskop tertentu
  Future<List<MovieModel>> getPlayingMoviesForCinema(String cinemaId) async {
    try {
      final result = await _movieService.getNowPlaying();
      if (result.movies.isNotEmpty) {
        return result.movies;
      }
    } catch (e) {
      debugPrint('[ShowtimeService] Error getting now playing movies: $e');
    }
    return MovieService.mockNowPlaying;
  }

  /// Mengambil jadwal tayang film di suatu bioskop untuk tanggal tertentu
  Future<List<ShowtimeModel>> getShowtimes({
    required String cinemaId,
    required String date,
    required int movieId,
    required String movieTitle,
  }) async {
    // 1. Coba fetch dari Supabase showtimes jika ada
    try {
      final response = await _supabase.client
          .from('showtimes')
          .select()
          .eq('cinema_id', cinemaId)
          .eq('show_date', date);

      if (response.isNotEmpty) {
        return response.map((row) => ShowtimeModel.fromJson(row)).toList();
      }
    } catch (e) {
      debugPrint('[ShowtimeService] Supabase showtimes fetch info: $e');
    }

    // 2. Generate jadwal realistis berdasarkan studio & kelas bioskop (Seed Fallback)
    return _generateCuratedShowtimes(
      cinemaId: cinemaId,
      date: date,
      movieId: movieId,
      movieTitle: movieTitle,
    );
  }

  /// Generator jadwal tayang realistis untuk demo dan pemesanan multi-studio
  List<ShowtimeModel> _generateCuratedShowtimes({
    required String cinemaId,
    required String date,
    required int movieId,
    required String movieTitle,
  }) {
    final list = <ShowtimeModel>[];

    // Studio 1: Regular 2D
    const regularTimes = ['11:30', '14:00', '16:45', '19:15', '21:30'];
    for (int i = 0; i < regularTimes.length; i++) {
      list.add(
        ShowtimeModel(
          id: '${cinemaId}_${movieId}_${date}_reg_$i',
          cinemaId: cinemaId,
          movieId: movieId,
          movieTitle: movieTitle,
          showDate: date,
          showTime: regularTimes[i],
          hallName: 'Studio 1',
          experience: 'Regular 2D',
          price: 50000,
          totalSeats: 120,
          availableSeats: 94 - (i * 12),
        ),
      );
    }

    // Studio 2: IMAX with Laser
    const imaxTimes = ['12:15', '15:15', '18:15', '21:00'];
    for (int i = 0; i < imaxTimes.length; i++) {
      list.add(
        ShowtimeModel(
          id: '${cinemaId}_${movieId}_${date}_imax_$i',
          cinemaId: cinemaId,
          movieId: movieId,
          movieTitle: movieTitle,
          showDate: date,
          showTime: imaxTimes[i],
          hallName: 'Studio 2 (IMAX)',
          experience: 'IMAX with Laser',
          price: 75000,
          totalSeats: 150,
          availableSeats: 110 - (i * 15),
        ),
      );
    }

    // Studio 3: The Premiere / Velvet
    const premiereTimes = ['13:00', '16:00', '19:00', '21:45'];
    for (int i = 0; i < premiereTimes.length; i++) {
      list.add(
        ShowtimeModel(
          id: '${cinemaId}_${movieId}_${date}_prem_$i',
          cinemaId: cinemaId,
          movieId: movieId,
          movieTitle: movieTitle,
          showDate: date,
          showTime: premiereTimes[i],
          hallName: 'Premiere Lounge',
          experience: 'The Premiere',
          price: 100000,
          totalSeats: 48,
          availableSeats: 36 - (i * 6),
        ),
      );
    }

    return list;
  }
}
