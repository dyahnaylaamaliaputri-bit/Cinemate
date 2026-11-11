// lib/models/showtime_model.dart
// Model jadwal penayangan film (Showtime) untuk alur pemesanan tiket (PB-018)
// Referensi: SRS §3.1, PB-018, tabel Supabase `showtimes`

import '../utils/currency_helper.dart';
import '../utils/timezone_helper.dart';

class ShowtimeModel {
  final String id;
  final String cinemaId;
  final int movieId;
  final String movieTitle;
  final String showDate; // format: 'YYYY-MM-DD'
  final String showTime; // format: 'HH:mm', contoh '13:00'
  final String hallName; // contoh: 'Studio 1', 'Studio 2'
  final String experience; // contoh: 'Regular 2D', 'IMAX', 'Premiere'
  final int price; // harga dalam Rupiah (contoh: 50000)
  final int totalSeats;
  final int availableSeats;

  const ShowtimeModel({
    required this.id,
    required this.cinemaId,
    required this.movieId,
    required this.movieTitle,
    required this.showDate,
    required this.showTime,
    required this.hallName,
    this.experience = 'Regular 2D',
    this.price = 50000,
    this.totalSeats = 100,
    this.availableSeats = 82,
  });

  factory ShowtimeModel.fromJson(Map<String, dynamic> json) {
    return ShowtimeModel(
      id: json['id'] as String? ?? '',
      cinemaId: json['cinema_id'] as String? ?? '',
      movieId: json['movie_id'] is int
          ? json['movie_id'] as int
          : int.tryParse(json['movie_id']?.toString() ?? '0') ?? 0,
      movieTitle: json['movie_title'] as String? ?? '',
      showDate: json['show_date'] as String? ?? '',
      showTime: json['show_time'] as String? ?? '',
      hallName: json['hall_name'] as String? ?? 'Studio 1',
      experience: json['experience'] as String? ?? 'Regular 2D',
      price: json['price'] as int? ?? 50000,
      totalSeats: json['total_seats'] as int? ?? 100,
      availableSeats: json['available_seats'] as int? ?? 82,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cinema_id': cinemaId,
      'movie_id': movieId,
      'movie_title': movieTitle,
      'show_date': showDate,
      'show_time': showTime,
      'hall_name': hallName,
      'experience': experience,
      'price': price,
      'total_seats': totalSeats,
      'available_seats': availableSeats,
    };
  }

  ShowtimeModel copyWith({
    String? id,
    String? cinemaId,
    int? movieId,
    String? movieTitle,
    String? showDate,
    String? showTime,
    String? hallName,
    String? experience,
    int? price,
    int? totalSeats,
    int? availableSeats,
  }) {
    return ShowtimeModel(
      id: id ?? this.id,
      cinemaId: cinemaId ?? this.cinemaId,
      movieId: movieId ?? this.movieId,
      movieTitle: movieTitle ?? this.movieTitle,
      showDate: showDate ?? this.showDate,
      showTime: showTime ?? this.showTime,
      hallName: hallName ?? this.hallName,
      experience: experience ?? this.experience,
      price: price ?? this.price,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
    );
  }

  /// Format harga dalam Rupiah (contoh: "Rp 50.000")
  String get formattedPrice {
    final str = price.toString();
    final buffer = StringBuffer('Rp ');
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Format harga sesuai preferensi mata uang terpilih (PB-048)
  String formattedPriceWithCurrency([String targetCurrency = 'IDR']) {
    return CurrencyHelper.format(price, targetCurrency: targetCurrency);
  }

  /// Format jam tayang sesuai zona waktu terpilih (PB-049)
  String formattedTimeWithZone([String targetZone = 'WIB']) {
    return TimezoneHelper.convertTimeString(showTime, targetZone: targetZone);
  }
}
