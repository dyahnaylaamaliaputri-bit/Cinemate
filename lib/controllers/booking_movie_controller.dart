// lib/controllers/booking_movie_controller.dart
// Controller untuk alur pemesanan tiket berbasis film: Pilih Film -> Filter Bioskop -> Pilih Tanggal & Jam (PB-019)

import 'package:get/get.dart';
import '../models/cinema_model.dart';
import '../models/movie_model.dart';
import '../models/showtime_model.dart';
import '../services/movie_service.dart';
import '../services/showtime_service.dart';
import 'cinema_controller.dart';

class BookByMovieController extends GetxController {
  final ShowtimeService _showtimeService = ShowtimeService();
  final MovieService _movieService = MovieService();

  /// Film yang sedang dipilih
  final Rx<MovieModel?> selectedMovie = Rx<MovieModel?>(null);

  /// Semua film Now Playing (untuk pemilih ganti film)
  final allMovies = <MovieModel>[].obs;

  /// 7 hari kalender mendatang
  final availableDates = <DateTime>[].obs;

  /// Tanggal yang sedang dipilih
  final Rx<DateTime> selectedDate = Rx<DateTime>(DateTime.now());

  /// Daftar bioskop yang menayangkan film ini (diurutkan berdasarkan jarak LBS)
  final cinemas = <CinemaModel>[].obs;

  /// Map jadwal tayang: `cinemaId -> List<ShowtimeModel>`
  final cinemaShowtimes = <String, List<ShowtimeModel>>{}.obs;

  /// ID bioskop yang kartunya sedang terbuka / expanded
  final expandedCinemaId = ''.obs;

  /// Bioskop dan Showtime yang dipilih pengguna
  final Rx<CinemaModel?> selectedCinema = Rx<CinemaModel?>(null);
  final Rx<ShowtimeModel?> selectedShowtime = Rx<ShowtimeModel?>(null);

  final isLoading = false.obs;
  final isLoadingShowtimes = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initUpcomingDates();
  }

  /// Membuat daftar 7 hari kalender mendatang mulai dari hari ini
  void _initUpcomingDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    availableDates.assignAll(
      List.generate(7, (index) => today.add(Duration(days: index))),
    );
    selectedDate.value = today;
  }

  /// Inisialisasi dengan film tertentu
  Future<void> setMovie(MovieModel movie) async {
    selectedMovie.value = movie;
    await _loadAllMovies();
    await _loadCinemasAndShowtimes();
  }

  /// Inisialisasi default jika dibuka tanpa argumen film
  Future<void> initDefaultMovie() async {
    await _loadAllMovies();
    if (allMovies.isNotEmpty && selectedMovie.value == null) {
      await setMovie(allMovies.first);
    }
  }

  Future<void> _loadAllMovies() async {
    try {
      final res = await _movieService.getNowPlaying();
      if (res.movies.isNotEmpty) {
        allMovies.assignAll(res.movies);
      } else {
        allMovies.assignAll(MovieService.mockNowPlaying);
      }
    } catch (_) {
      allMovies.assignAll(MovieService.mockNowPlaying);
    }
  }

  /// Memuat bioskop yang menayangkan film ini beserta jadwal tayangnya
  Future<void> _loadCinemasAndShowtimes() async {
    final movie = selectedMovie.value;
    if (movie == null) return;

    try {
      isLoading.value = true;
      selectedShowtime.value = null;
      selectedCinema.value = null;

      // Ambil koordinat pengguna saat ini jika CinemaController terdaftar
      double lat = -6.2000;
      double lng = 106.8167;
      if (Get.isRegistered<CinemaController>()) {
        final cinemaCtrl = Get.find<CinemaController>();
        lat = cinemaCtrl.userLat.value;
        lng = cinemaCtrl.userLng.value;
      }

      // Ambil daftar bioskop yang menayangkan film ini
      final list = await _showtimeService.getCinemasForMovie(
        movie.id,
        userLat: lat,
        userLng: lng,
      );
      cinemas.assignAll(list);

      if (list.isNotEmpty) {
        expandedCinemaId.value = list.first.id; // buka bioskop terdekat #1 secara default
      }

      await loadShowtimesForAllCinemas();
    } finally {
      isLoading.value = false;
    }
  }

  /// Memuat jadwal tayang film di semua bioskop untuk tanggal terpilih
  Future<void> loadShowtimesForAllCinemas() async {
    final movie = selectedMovie.value;
    if (movie == null || cinemas.isEmpty) return;

    try {
      isLoadingShowtimes.value = true;
      final dateStr = formatDateKey(selectedDate.value);
      final newMap = <String, List<ShowtimeModel>>{};

      for (final cinema in cinemas) {
        final stList = await _showtimeService.getShowtimes(
          cinemaId: cinema.id,
          date: dateStr,
          movieId: movie.id,
          movieTitle: movie.title,
        );
        newMap[cinema.id] = stList;
      }

      cinemaShowtimes.assignAll(newMap);
    } finally {
      isLoadingShowtimes.value = false;
    }
  }

  /// Mengubah pilihan film (PB-019)
  void changeMovie(MovieModel movie) {
    selectedMovie.value = movie;
    _loadCinemasAndShowtimes();
  }

  /// Mengubah pilihan tanggal tayang
  void changeDate(DateTime date) {
    selectedDate.value = date;
    selectedShowtime.value = null; // reset seleksi jam
    loadShowtimesForAllCinemas();
  }

  /// Toggle accordion bioskop (buka / tutup kartu)
  void toggleCinema(String cinemaId) {
    if (expandedCinemaId.value == cinemaId) {
      expandedCinemaId.value = '';
    } else {
      expandedCinemaId.value = cinemaId;
    }
  }

  /// Memilih jadwal tayang pada bioskop tertentu
  void selectShowtime(CinemaModel cinema, ShowtimeModel showtime) {
    if (selectedShowtime.value?.id == showtime.id) {
      selectedShowtime.value = null;
      selectedCinema.value = null;
    } else {
      selectedCinema.value = cinema;
      selectedShowtime.value = showtime;
    }
  }

  /// Format tanggal YYYY-MM-DD
  String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Apakah pengguna siap lanjut ke alur pemilihan kursi
  bool get canProceed => selectedShowtime.value != null && selectedCinema.value != null;
}
