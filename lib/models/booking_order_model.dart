// lib/models/booking_order_model.dart
// Model untuk Ringkasan Pesanan (Order Summary) tiket bioskop (PB-020)

import 'cinema_model.dart';
import 'movie_model.dart';
import 'showtime_model.dart';

class BookingOrderModel {
  final String id;
  final MovieModel movie;
  final CinemaModel cinema;
  final ShowtimeModel showtime;
  final List<String> selectedSeats;
  final int ticketPrice;
  final int serviceFeePerTicket;
  final DateTime createdAt;
  final String status; // 'pending', 'paid', 'cancelled'

  BookingOrderModel({
    required this.id,
    required this.movie,
    required this.cinema,
    required this.showtime,
    required this.selectedSeats,
    required this.ticketPrice,
    this.serviceFeePerTicket = 3000,
    required this.createdAt,
    this.status = 'pending',
  });

  /// Jumlah kursi yang dipesan
  int get seatCount => selectedSeats.length;

  /// Subtotal harga tiket bioskop
  int get subtotal => ticketPrice * seatCount;

  /// Total biaya layanan aplikasi
  int get totalServiceFee => serviceFeePerTicket * seatCount;

  /// Total tagihan keseluruhan yang harus dibayar pengguna
  int get totalAmount => subtotal + totalServiceFee;

  /// String gabungan label kursi, misal: "C4, C5"
  String get seatsLabel {
    if (selectedSeats.isEmpty) return '-';
    final sorted = List<String>.from(selectedSeats)..sort();
    return sorted.join(', ');
  }

  /// Format rupiah: Rp 50.000
  static String formatRupiah(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  String get formattedSubtotal => formatRupiah(subtotal);
  String get formattedServiceFee => formatRupiah(totalServiceFee);
  String get formattedTicketPrice => formatRupiah(ticketPrice);
  String get formattedTotalAmount => formatRupiah(totalAmount);

  /// Format tanggal penayangan yang manusiawi (misal: "Sabtu, 7 November 2026")
  String get formattedShowDate {
    try {
      final parts = showtime.showDate.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final dt = DateTime(year, month, day);

        const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        const months = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];
        return '${days[dt.weekday - 1]}, $day ${months[month - 1]} $year';
      }
    } catch (_) {}
    return showtime.showDate;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie': movie.toJson(),
      'cinema': cinema.toJson(),
      'showtime': showtime.toJson(),
      'selected_seats': selectedSeats,
      'ticket_price': ticketPrice,
      'service_fee_per_ticket': serviceFeePerTicket,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory BookingOrderModel.fromJson(Map<String, dynamic> json) {
    return BookingOrderModel(
      id: json['id'] as String? ?? 'ORD-000',
      movie: MovieModel.fromJson(Map<String, dynamic>.from(json['movie'] as Map)),
      cinema: CinemaModel.fromJson(Map<String, dynamic>.from(json['cinema'] as Map)),
      showtime: ShowtimeModel.fromJson(Map<String, dynamic>.from(json['showtime'] as Map)),
      selectedSeats: (json['selected_seats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ticketPrice: json['ticket_price'] as int? ?? 50000,
      serviceFeePerTicket: json['service_fee_per_ticket'] as int? ?? 3000,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'pending',
    );
  }
}
