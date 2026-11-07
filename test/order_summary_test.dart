// test/order_summary_test.dart
// Pengujian unit model dan kalkulasi Ringkasan Pesanan (PB-020)

import 'package:cinemate/models/booking_order_model.dart';
import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/models/seat_model.dart';
import 'package:cinemate/models/showtime_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeatModel Tests (PB-020)', () {
    test('SeatModel should parse json and check availability status properly', () {
      final seatAvailable = SeatModel(
        id: 'A1',
        row: 'A',
        column: 1,
        status: SeatStatus.available,
        price: 50000,
      );

      expect(seatAvailable.id, 'A1');
      expect(seatAvailable.isAvailable, true);
      expect(seatAvailable.isSelected, false);
      expect(seatAvailable.isReserved, false);

      final seatSelected = seatAvailable.copyWith(status: SeatStatus.selected);
      expect(seatSelected.isSelected, true);
      expect(seatSelected.isAvailable, false);

      final seatReserved = seatAvailable.copyWith(status: SeatStatus.reserved);
      expect(seatReserved.isReserved, true);
    });

    test('SeatModel serialization and deserialization', () {
      final seat = SeatModel(
        id: 'C4',
        row: 'C',
        column: 4,
        status: SeatStatus.reserved,
        price: 75000,
      );

      final json = seat.toJson();
      expect(json['id'], 'C4');
      expect(json['status'], 'reserved');
      expect(json['price'], 75000);

      final parsed = SeatModel.fromJson(json);
      expect(parsed.id, 'C4');
      expect(parsed.isReserved, true);
      expect(parsed.price, 75000);
    });
  });

  group('BookingOrderModel Tests (PB-020)', () {
    final movie = MovieModel(
      id: 533535,
      title: 'Deadpool & Wolverine',
      overview: 'Wade Wilson and Logan team up.',
      voteAverage: 7.9,
      voteCount: 1500,
      genreIds: [28, 35, 878],
      popularity: 300.0,
      releaseDate: '2024-07-24',
    );

    final cinema = CinemaModel(
      id: 'cin-1',
      name: 'Metro Cinema Senayan',
      address: 'Jl. Asia Afrika No. 8, Jakarta Selatan',
      latitude: -6.2176,
      longitude: 106.8013,
      distanceKm: 2.6,
    );

    final showtime = ShowtimeModel(
      id: 'st-101',
      cinemaId: 'cin-1',
      movieId: 533535,
      movieTitle: 'Deadpool & Wolverine',
      showDate: '2026-11-07',
      showTime: '14:00',
      hallName: 'Studio 1',
      experience: 'Regular 2D',
      price: 50000,
      totalSeats: 56,
      availableSeats: 48,
    );

    test('BookingOrderModel should accurately compute subtotal, service fee, and total amount', () {
      final order = BookingOrderModel(
        id: 'ORD-2026-001',
        movie: movie,
        cinema: cinema,
        showtime: showtime,
        selectedSeats: ['C4', 'C5'],
        ticketPrice: 50000,
        serviceFeePerTicket: 3000,
        createdAt: DateTime(2026, 11, 7, 12, 0),
      );

      // 1. Jumlah Kursi
      expect(order.seatCount, 2);

      // 2. Subtotal: Rp 50.000 x 2 = Rp 100.000
      expect(order.subtotal, 100000);
      expect(order.formattedSubtotal, 'Rp 100.000');

      // 3. Biaya Layanan: Rp 3.000 x 2 = Rp 6.000
      expect(order.totalServiceFee, 6000);
      expect(order.formattedServiceFee, 'Rp 6.000');

      // 4. Total Tagihan: Rp 100.000 + Rp 6.000 = Rp 106.000
      expect(order.totalAmount, 106000);
      expect(order.formattedTotalAmount, 'Rp 106.000');

      // 5. Label Kursi
      expect(order.seatsLabel, 'C4, C5');

      // 6. Tanggal Tayang Manusiawi
      expect(order.formattedShowDate, contains('7 November 2026'));
    });

    test('BookingOrderModel should sort seat labels alphabetically', () {
      final order = BookingOrderModel(
        id: 'ORD-2026-002',
        movie: movie,
        cinema: cinema,
        showtime: showtime,
        selectedSeats: ['D2', 'A5', 'B1'],
        ticketPrice: 75000,
        serviceFeePerTicket: 3000,
        createdAt: DateTime.now(),
      );

      expect(order.seatCount, 3);
      expect(order.seatsLabel, 'A5, B1, D2');
      expect(order.subtotal, 225000);
      expect(order.totalServiceFee, 9000);
      expect(order.totalAmount, 234000);
      expect(order.formattedTotalAmount, 'Rp 234.000');
    });

    test('BookingOrderModel serialization and deserialization roundtrip', () {
      final order = BookingOrderModel(
        id: 'ORD-ROUNDTRIP',
        movie: movie,
        cinema: cinema,
        showtime: showtime,
        selectedSeats: ['E3', 'E4'],
        ticketPrice: 100000,
        serviceFeePerTicket: 3000,
        createdAt: DateTime(2026, 11, 7, 10, 30),
      );

      final json = order.toJson();
      expect(json['id'], 'ORD-ROUNDTRIP');
      expect(json['ticket_price'], 100000);
      expect(json['selected_seats'], ['E3', 'E4']);

      final restored = BookingOrderModel.fromJson(json);
      expect(restored.id, 'ORD-ROUNDTRIP');
      expect(restored.movie.title, 'Deadpool & Wolverine');
      expect(restored.cinema.name, 'Metro Cinema Senayan');
      expect(restored.selectedSeats, ['E3', 'E4']);
      expect(restored.totalAmount, 206000);
      expect(restored.formattedTotalAmount, 'Rp 206.000');
    });
  });
}
