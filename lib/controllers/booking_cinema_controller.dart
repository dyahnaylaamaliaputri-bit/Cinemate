// lib/controllers/booking_cinema_controller.dart
// Controller untuk alur pemesanan tiket berbasis bioskop: Pilih Bioskop -> Pilih Film -> Pilih Tanggal & Jam (PB-018)

import 'package:get/get.dart';
import '../models/cinema_model.dart';
import '../models/movie_model.dart';
import '../models/showtime_model.dart';
import '../services/cinema_service.dart';
import '../services/showtime_service.dart';

class BookByCinemaController extends GetxController {
  final CinemaService _cinemaService = CinemaService();
  final ShowtimeService _showtimeService = ShowtimeService();

  /// Bioskop yang sedang dipilih
  final Rx<CinemaModel?> selectedCinema = Rx<CinemaModel?>(null);

  /// Daftar semua bioskop yang tersedia (untuk pergantian bioskop)
  final allCinemas = <CinemaModel>[].obs;

  /// Film yang tayang di bioskop ini
  final moviesAtCinema = <MovieModel>[].obs;

  /// Film yang sedang dipilih
  final Rx<MovieModel?> selectedMovie = Rx<MovieModel?>(null);

  /// 7 hari tanggal pemesanan mendatang
  final availableDates = <DateTime>[].obs;

  /// Tanggal yang sedang dipilih
  final Rx<DateTime> selectedDate = Rx<DateTime>(DateTime.now());

  /// Daftar jadwal tayang untuk kombinasi Bioskop + Film + Tanggal
  final showtimes = <ShowtimeModel>[].obs;

  /// Jadwal tayang (Showtime) yang dipilih pengguna
  final Rx<ShowtimeModel?> selectedShowtime = Rx<ShowtimeModel?>(null);

  final isLoading = false.obs;
  final isLoadingShowtimes = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initUpcomingDates();
    _loadAllCinemas();
  }

  /// Membuat daftar 7 hari kalender mulai dari hari ini
  void _initUpcomingDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    availableDates.assignAll(
      List.generate(7, (index) => today.add(Duration(days: index))),
    );
    selectedDate.value = today;
  }

  /// Memuat daftar semua bioskop untuk opsi switcher
  Future<void> _loadAllCinemas() async {
    final result = await _cinemaService.getAllCinemas();
    allCinemas.assignAll(result.cinemas);
  }

  /// Menginisialisasi bioskop terpilih (dipanggil saat halaman dibuka dengan argument CinemaModel)
  Future<void> setCinema(CinemaModel cinema, {MovieModel? initialMovie}) async {
    selectedCinema.value = cinema;
    await _loadMoviesForCinema(initialMovie: initialMovie);
  }

  /// Inisialisasi bioskop default jika dibuka tanpa argumen bioskop
  Future<void> initDefaultCinema({MovieModel? initialMovie}) async {
    if (allCinemas.isEmpty) {
      await _loadAllCinemas();
    }
    if (allCinemas.isNotEmpty) {
      final cinemaToUse = selectedCinema.value ?? allCinemas.first;
      await setCinema(cinemaToUse, initialMovie: initialMovie);
    }
  }

  /// Memuat film yang tayang di bioskop terpilih
  Future<void> _loadMoviesForCinema({MovieModel? initialMovie}) async {
    if (selectedCinema.value == null) return;
    try {
      isLoading.value = true;
      final list = await _showtimeService
          .getPlayingMoviesForCinema(selectedCinema.value!.id);
      moviesAtCinema.assignAll(list);

      // Pilih initial movie jika ada, atau default ke film pertama
      if (initialMovie != null && list.any((m) => m.id == initialMovie.id)) {
        selectedMovie.value = initialMovie;
      } else if (list.isNotEmpty) {
        selectedMovie.value = list.first;
      }

      await loadShowtimes();
    } finally {
      isLoading.value = false;
    }
  }

  /// Memuat jadwal tayang film berdasarkan bioskop, film, dan tanggal terpilih
  Future<void> loadShowtimes() async {
    final cinema = selectedCinema.value;
    final movie = selectedMovie.value;
    if (cinema == null || movie == null) return;

    try {
      isLoadingShowtimes.value = true;
      selectedShowtime.value = null; // reset seleksi jam sebelumnya

      final dateStr = formatDateKey(selectedDate.value);
      final list = await _showtimeService.getShowtimes(
        cinemaId: cinema.id,
        date: dateStr,
        movieId: movie.id,
        movieTitle: movie.title,
      );
      showtimes.assignAll(list);
    } finally {
      isLoadingShowtimes.value = false;
    }
  }

  /// Mengubah pilihan bioskop
  void changeCinema(CinemaModel cinema) {
    selectedCinema.value = cinema;
    _loadMoviesForCinema();
  }

  /// Mengubah pilihan film
  void changeMovie(MovieModel movie) {
    selectedMovie.value = movie;
    loadShowtimes();
  }

  /// Mengubah pilihan tanggal
  void changeDate(DateTime date) {
    selectedDate.value = date;
    loadShowtimes();
  }

  /// Memilih salah satu jam tayang
  void selectShowtime(ShowtimeModel showtime) {
    if (selectedShowtime.value?.id == showtime.id) {
      selectedShowtime.value = null; // toggle unselect
    } else {
      selectedShowtime.value = showtime;
    }
  }

  /// Format tanggal standar YYYY-MM-DD
  String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Daftar jenis studio/pengalaman unik yang ada di jadwal saat ini
  List<String> get uniqueExperiences {
    final set = <String>{};
    for (final s in showtimes) {
      set.add(s.experience);
    }
    return set.toList();
  }

  /// Mengambil jadwal tayang untuk tipe studio/pengalaman tertentu
  List<ShowtimeModel> showtimesForExperience(String experience) {
    return showtimes.where((s) => s.experience == experience).toList();
  }

  /// Apakah pengguna sudah memilih jadwal dan siap lanjut ke pemilihan kursi
  bool get canProceed => selectedShowtime.value != null;
}
