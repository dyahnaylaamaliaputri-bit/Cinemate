// lib/models/ticket_model.dart
// Model untuk E-Ticket bioskop dengan QR Code dan persistensi (PB-022, PB-023)

import 'booking_order_model.dart';

class TicketModel {
  final String id;
  final String bookingCode; // Format: "CNM-XXXXX"
  final String userId;
  final String showtimeId;
  final int movieId;
  final String movieTitle;
  final String? posterPath;
  final String? backdropPath;
  final String cinemaId;
  final String cinemaName;
  final String cinemaAddress;
  final String hallName; // "Studio 1"
  final String experience; // "Regular 2D", "IMAX with Laser"
  final String showDate; // "2026-11-07"
  final String showTime; // "14:00"
  final List<String> seats; // ["C2", "C3"]
  final int totalPrice;
  final String qrData;
  final String status; // 'paid', 'used', 'expired', 'cancelled'
  final String? paymentMethod;
  final String? paymentReference;
  final DateTime createdAt;

  TicketModel({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.showtimeId,
    required this.movieId,
    required this.movieTitle,
    this.posterPath,
    this.backdropPath,
    required this.cinemaId,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.hallName,
    required this.experience,
    required this.showDate,
    required this.showTime,
    required this.seats,
    required this.totalPrice,
    required this.qrData,
    this.status = 'paid',
    this.paymentMethod,
    this.paymentReference,
    required this.createdAt,
  });

  /// URL poster TMDB lengkap
  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    if (posterPath!.startsWith('http')) return posterPath!;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// URL backdrop TMDB
  String get backdropUrl {
    if (backdropPath == null || backdropPath!.isEmpty) return posterUrl;
    if (backdropPath!.startsWith('http')) return backdropPath!;
    return 'https://image.tmdb.org/t/p/w780$backdropPath';
  }

  int get seatCount => seats.length;

  /// String daftar kursi tersortir, misal: "C2, C3"
  String get seatsLabel {
    if (seats.isEmpty) return '-';
    final sorted = List<String>.from(seats)..sort();
    return sorted.join(', ');
  }

  /// Format rupiah: Rp 106.000
  String get formattedPrice => BookingOrderModel.formatRupiah(totalPrice);

  /// Status tiket aktif (bisa digunakan untuk check-in / masuk studio)
  bool get isActive => status == 'paid' || status == 'active';
  bool get isUsed => status == 'used';
  bool get isExpired => status == 'expired' || status == 'cancelled';

  /// Format tanggal penayangan manusiawi (misal: "Sabtu, 7 November 2026")
  String get formattedShowDate {
    try {
      final parts = showDate.split('-');
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
    return showDate;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_code': bookingCode,
      'user_id': userId,
      'showtime_id': showtimeId,
      'movie_id': movieId,
      'movie_title': movieTitle,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'cinema_id': cinemaId,
      'cinema_name': cinemaName,
      'cinema_address': cinemaAddress,
      'hall_name': hallName,
      'experience': experience,
      'show_date': showDate,
      'show_time': showTime,
      'seats': seats,
      'total_price': totalPrice,
      'qr_data': qrData,
      'status': status,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id']?.toString() ?? 'TKT-000',
      bookingCode: json['booking_code']?.toString() ?? 'CNM-00000',
      userId: json['user_id']?.toString() ?? '',
      showtimeId: json['showtime_id']?.toString() ?? '',
      movieId: json['movie_id'] is int ? json['movie_id'] as int : int.tryParse(json['movie_id']?.toString() ?? '0') ?? 0,
      movieTitle: json['movie_title']?.toString() ?? 'Untitled Movie',
      posterPath: json['poster_path']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
      cinemaId: json['cinema_id']?.toString() ?? '',
      cinemaName: json['cinema_name']?.toString() ?? 'Cinemate Cinema',
      cinemaAddress: json['cinema_address']?.toString() ?? 'Jakarta',
      hallName: json['hall_name']?.toString() ?? 'Studio 1',
      experience: json['experience']?.toString() ?? 'Regular 2D',
      showDate: json['show_date']?.toString() ?? '',
      showTime: json['show_time']?.toString() ?? '',
      seats: (json['seats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalPrice: json['total_price'] is int
          ? json['total_price'] as int
          : int.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
      qrData: json['qr_data']?.toString() ?? 'CINEMATE',
      status: json['status']?.toString() ?? 'paid',
      paymentMethod: json['payment_method']?.toString(),
      paymentReference: json['payment_reference']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
