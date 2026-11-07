// lib/controllers/booking_seat_controller.dart
// Controller pemilihan kursi bioskop (PB-020)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/booking_order_model.dart';
import '../models/cinema_model.dart';
import '../models/movie_model.dart';
import '../models/seat_model.dart';
import '../models/showtime_model.dart';
import '../routes/app_routes.dart';

class BookingSeatController extends GetxController {
  late final MovieModel movie;
  late final CinemaModel cinema;
  late final ShowtimeModel showtime;

  /// Daftar baris kursi di studio (A s/d G)
  final rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

  /// Jumlah kursi per baris
  final int seatsPerRow = 8;

  /// Map seluruh kursi: "A1" -> SeatModel
  final seatsMap = <String, SeatModel>{}.obs;

  /// Daftar kursi yang sedang dipilih pengguna (misal: ["C4", "C5"])
  final selectedSeats = <String>[].obs;

  /// Maksimal kursi per pemesanan
  final int maxSeats = 6;

  @override
  void onInit() {
    super.onInit();
    _initArguments();
    _generateSeatsLayout();
  }

  void _initArguments() {
    final args = Get.arguments;
    if (args is Map) {
      if (args['movie'] is MovieModel) {
        movie = args['movie'] as MovieModel;
      } else {
        movie = MovieModel(
          id: 1,
          title: 'Cinemate Movie',
          overview: '',
          voteAverage: 8.0,
          voteCount: 100,
          genreIds: [28],
          popularity: 100.0,
        );
      }

      if (args['cinema'] is CinemaModel) {
        cinema = args['cinema'] as CinemaModel;
      } else {
        cinema = CinemaModel(
          id: 'cin-1',
          name: 'Cinemate Cinema',
          address: 'Jakarta',
          latitude: -6.2088,
          longitude: 106.8456,
        );
      }

      if (args['showtime'] is ShowtimeModel) {
        showtime = args['showtime'] as ShowtimeModel;
      } else {
        showtime = ShowtimeModel(
          id: 'st-default',
          cinemaId: cinema.id,
          movieId: movie.id,
          movieTitle: movie.title,
          showDate: DateTime.now().toString().substring(0, 10),
          showTime: '14:00',
          hallName: 'Studio 1',
          experience: 'Regular 2D',
          price: 50000,
          totalSeats: 56,
          availableSeats: 48,
        );
      }
    }
  }

  /// Menghasilkan tata letak kursi dan menandai kursi yang sudah terisi (reserved)
  void _generateSeatsLayout() {
    // Kursi yang terisi di-generate secara deterministik berdasarkan id showtime
    final seed = showtime.id.hashCode.abs();
    final reservedSet = <String>{};

    for (final r in rows) {
      for (int c = 1; c <= seatsPerRow; c++) {
        final id = '$r$c';
        // Simulasikan sekitar 15-25% kursi terisi
        final hash = (seed + id.hashCode).abs();
        if (hash % 5 == 0 && reservedSet.length < (showtime.totalSeats - showtime.availableSeats)) {
          reservedSet.add(id);
        }
      }
    }

    final newMap = <String, SeatModel>{};
    for (final r in rows) {
      for (int c = 1; c <= seatsPerRow; c++) {
        final id = '$r$c';
        final isReserved = reservedSet.contains(id);
        newMap[id] = SeatModel(
          id: id,
          row: r,
          column: c,
          status: isReserved ? SeatStatus.reserved : SeatStatus.available,
          price: showtime.price,
        );
      }
    }
    seatsMap.value = newMap;
  }

  /// Toggle seleksi kursi
  void toggleSeat(String seatId) {
    final seat = seatsMap[seatId];
    if (seat == null || seat.isReserved) return;

    if (selectedSeats.contains(seatId)) {
      selectedSeats.remove(seatId);
      seatsMap[seatId] = seat.copyWith(status: SeatStatus.available);
    } else {
      if (selectedSeats.length >= maxSeats) {
        Get.snackbar(
          'Batas Kursi Tercapai',
          'Anda hanya dapat memilih maksimal $maxSeats kursi dalam satu pemesanan.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF16213E),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.info_outline, color: Color(0xFFFFD700)),
        );
        return;
      }
      selectedSeats.add(seatId);
      seatsMap[seatId] = seat.copyWith(status: SeatStatus.selected);
    }
  }

  /// Total harga tiket berdasarkan jumlah kursi terpilih
  int get subtotal => showtime.price * selectedSeats.length;

  /// String rupiah subtotal
  String get formattedSubtotal => BookingOrderModel.formatRupiah(subtotal);

  /// Label kursi terpilih (misal: "A1, A2")
  String get selectedSeatsLabel {
    if (selectedSeats.isEmpty) return 'Belum ada kursi yang dipilih';
    final sorted = List<String>.from(selectedSeats)..sort();
    return sorted.join(', ');
  }

  /// Melanjutkan ke halaman Ringkasan Pesanan (PB-020)
  void proceedToOrderSummary() {
    if (selectedSeats.isEmpty) {
      Get.snackbar(
        'Pilih Kursi',
        'Silakan pilih minimal 1 kursi bioskop untuk melanjutkan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF16213E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.event_seat_rounded, color: Color(0xFFE50914)),
      );
      return;
    }

    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final order = BookingOrderModel(
      id: orderId,
      movie: movie,
      cinema: cinema,
      showtime: showtime,
      selectedSeats: List<String>.from(selectedSeats)..sort(),
      ticketPrice: showtime.price,
      serviceFeePerTicket: 3000,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    Get.toNamed(Routes.orderSummary, arguments: order);
  }
}
