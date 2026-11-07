// test/e_ticket_persistence_test.dart
// Pengujian unit E-Ticket, QR Code, dan persistensi Supabase / Hive (PB-022, PB-023)

import 'dart:io';
import 'package:cinemate/models/booking_order_model.dart';
import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/models/showtime_model.dart';
import 'package:cinemate/models/ticket_model.dart';
import 'package:cinemate/services/ticket_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => tempDir.path,
    );
  });

  group('TicketModel Tests (PB-022)', () {
    test('TicketModel should parse json and compute formatted fields correctly', () {
      final json = {
        'id': 'tkt-uuid-1',
        'booking_code': 'CNM-84920',
        'user_id': 'usr-123',
        'showtime_id': 'st-101',
        'movie_id': 533535,
        'movie_title': 'Deadpool & Wolverine',
        'poster_path': '/poster.jpg',
        'cinema_id': 'cin-1',
        'cinema_name': 'Metro Cinema Senayan',
        'cinema_address': 'Jl. Asia Afrika No. 8',
        'hall_name': 'Studio 1',
        'experience': 'Regular 2D',
        'show_date': '2026-11-07',
        'show_time': '14:00',
        'seats': ['C2', 'C3'],
        'total_price': 106000,
        'qr_data': 'CINEMATE:CNM-84920:2026-11-07:14:00:C2,C3',
        'status': 'paid',
        'payment_method': 'QRIS Bersama',
        'created_at': '2026-11-07T12:00:00.000Z',
      };

      final ticket = TicketModel.fromJson(json);

      expect(ticket.id, 'tkt-uuid-1');
      expect(ticket.bookingCode, 'CNM-84920');
      expect(ticket.seatCount, 2);
      expect(ticket.seatsLabel, 'C2, C3');
      expect(ticket.formattedPrice, 'Rp 106.000');
      expect(ticket.isActive, true);
      expect(ticket.isUsed, false);
      expect(ticket.isExpired, false);
      expect(ticket.formattedShowDate, contains('7 November 2026'));
      expect(ticket.posterUrl, contains('https://image.tmdb.org/t/p/w500/poster.jpg'));
    });

    test('TicketModel serialization roundtrip', () {
      final ticket = TicketModel(
        id: 'tkt-roundtrip',
        bookingCode: 'CNM-12345',
        userId: 'usr-1',
        showtimeId: 'st-1',
        movieId: 1,
        movieTitle: 'Inside Out 2',
        cinemaId: 'cin-1',
        cinemaName: 'Cinemate Plaza',
        cinemaAddress: 'Jl. Sudirman',
        hallName: 'Studio 2',
        experience: 'IMAX with Laser',
        showDate: '2026-11-08',
        showTime: '16:00',
        seats: ['D4'],
        totalPrice: 75000,
        qrData: 'CINEMATE:CNM-12345:2026-11-08:16:00:D4',
        createdAt: DateTime(2026, 11, 7),
      );

      final json = ticket.toJson();
      expect(json['booking_code'], 'CNM-12345');
      expect(json['total_price'], 75000);

      final parsed = TicketModel.fromJson(json);
      expect(parsed.bookingCode, 'CNM-12345');
      expect(parsed.seatsLabel, 'D4');
      expect(parsed.experience, 'IMAX with Laser');
    });
  });

  group('TicketService Booking & Hive Persistence Tests (PB-023)', () {
    test('generateBookingCode should return format CNM-XXXXX with 5 digits', () {
      final code = TicketService.generateBookingCode();
      expect(code, startsWith('CNM-'));
      expect(code.length, 9); // 'CNM-' (4) + 5 digit = 9
      final numPart = int.tryParse(code.substring(4));
      expect(numPart, isNotNull);
      expect(numPart, inInclusiveRange(10000, 99999));
    });

    test('generateQrPayload should format qr payload string properly', () {
      final payload = TicketService.generateQrPayload('CNM-99999', 'Dune 2', '2026-11-07', '19:00', ['A1', 'A2']);
      expect(payload, 'CINEMATE:CNM-99999:2026-11-07:19:00:A1,A2');
    });

    test('createBooking should persist ticket to Hive cache and be retrievable offline', () async {
      final service = TicketService();

      final movie = MovieModel(
        id: 533535,
        title: 'Deadpool & Wolverine',
        overview: 'Overview',
        voteAverage: 8.0,
        voteCount: 100,
        genreIds: [28],
        popularity: 100.0,
      );

      final cinema = CinemaModel(
        id: 'cin-1',
        name: 'Metro Cinema Senayan',
        address: 'Jl. Asia Afrika',
        latitude: -6.21,
        longitude: 106.8,
      );

      final showtime = ShowtimeModel(
        id: 'st-test',
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

      final order = BookingOrderModel(
        id: 'ORD-TEST-001',
        movie: movie,
        cinema: cinema,
        showtime: showtime,
        selectedSeats: ['C2', 'C3'],
        ticketPrice: 50000,
        serviceFeePerTicket: 3000,
        createdAt: DateTime.now(),
        status: 'paid',
        paymentMethod: 'QRIS',
      );

      final created = await service.createBooking(order: order, userId: 'usr-unit-test');

      expect(created.bookingCode, startsWith('CNM-'));
      expect(created.movieTitle, 'Deadpool & Wolverine');
      expect(created.seats, ['C2', 'C3']);
      expect(created.totalPrice, 106000);
      expect(created.isActive, true);

      // Verifikasi pembacaan dari Hive cache (Offline access PB-024)
      final userTickets = await service.getUserTickets();
      expect(userTickets, isNotEmpty);
      expect(userTickets.any((t) => t.id == created.id), true);

      final activeTickets = await service.getActiveTickets();
      expect(activeTickets.any((t) => t.id == created.id), true);
    });
  });
}
