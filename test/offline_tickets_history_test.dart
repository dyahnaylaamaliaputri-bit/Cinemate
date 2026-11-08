// test/offline_tickets_history_test.dart
// Unit Test untuk PB-024 (Akses E-Ticket Offline) & PB-025 (Daftar Tiket Aktif & Riwayat)

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/models/ticket_model.dart';
import 'package:cinemate/services/storage_service.dart';
import 'package:cinemate/services/ticket_service.dart';
import 'package:cinemate/controllers/tickets_controller.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;
  late TicketService ticketService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('cinemate_pb024_025_test_');
    Hive.init(tempDir.path);
    storage = StorageService();
    ticketService = TicketService();
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('TicketModel PB-024 & PB-025 Enhanced Tests', () {
    test('showDateTime should parse showDate and showTime properly', () {
      final ticket = TicketModel(
        id: 'tkt-1',
        bookingCode: 'CNM-12345',
        userId: 'u1',
        showtimeId: 'st-1',
        movieId: 101,
        movieTitle: 'Dune: Part Two',
        cinemaId: 'c1',
        cinemaName: 'Metro Cinema Senayan',
        cinemaAddress: 'Jl. Senayan',
        hallName: 'Studio 1',
        experience: 'Regular 2D',
        showDate: '2026-11-15',
        showTime: '19:30',
        seats: ['A1', 'A2'],
        totalPrice: 100000,
        qrData: 'CINEMATE://checkin?code=CNM-12345',
        status: 'paid',
        createdAt: DateTime.now(),
      );

      final dt = ticket.showDateTime;
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 11);
      expect(dt.day, 15);
      expect(dt.hour, 19);
      expect(dt.minute, 30);
    });

    test(
        'isTicketActive should be true for future showtime and false for past/used showtime',
        () {
      final futureTicket = TicketModel(
        id: 'tkt-future',
        bookingCode: 'CNM-88888',
        userId: 'u1',
        showtimeId: 'st-1',
        movieId: 101,
        movieTitle: 'Future Film',
        cinemaId: 'c1',
        cinemaName: 'Metro Cinema',
        cinemaAddress: 'Jakarta',
        hallName: 'Studio 1',
        experience: 'Regular 2D',
        showDate: '2099-01-01',
        showTime: '20:00',
        seats: ['B1'],
        totalPrice: 50000,
        qrData: 'CINEMATE://checkin',
        status: 'paid',
        createdAt: DateTime.now(),
      );

      final pastTicket = TicketModel(
        id: 'tkt-past',
        bookingCode: 'CNM-77777',
        userId: 'u1',
        showtimeId: 'st-2',
        movieId: 102,
        movieTitle: 'Past Film',
        cinemaId: 'c1',
        cinemaName: 'Metro Cinema',
        cinemaAddress: 'Jakarta',
        hallName: 'Studio 1',
        experience: 'Regular 2D',
        showDate: '2020-01-01',
        showTime: '10:00',
        seats: ['C1'],
        totalPrice: 50000,
        qrData: 'CINEMATE://checkin',
        status: 'paid',
        createdAt: DateTime.now(),
      );

      final usedTicket = futureTicket.copyWith(status: 'used');

      expect(futureTicket.isTicketActive, isTrue);
      expect(futureTicket.isTicketHistory, isFalse);

      expect(pastTicket.isTicketActive, isFalse);
      expect(pastTicket.isTicketHistory, isTrue);
      expect(pastTicket.historyStatusLabel, 'Selesai');

      expect(usedTicket.isTicketActive, isFalse);
      expect(usedTicket.isTicketHistory, isTrue);
      expect(usedTicket.historyStatusLabel, 'Sudah Ditonton');
    });

    test('remainingTimeLabel should return descriptive timing string', () {
      final ticketFuture = TicketModel(
        id: 'tkt-label',
        bookingCode: 'CNM-99999',
        userId: 'u1',
        showtimeId: 'st-1',
        movieId: 101,
        movieTitle: 'Label Film',
        cinemaId: 'c1',
        cinemaName: 'Cinema',
        cinemaAddress: 'Jakarta',
        hallName: 'Studio 1',
        experience: 'Regular 2D',
        showDate: '2099-12-31',
        showTime: '14:00',
        seats: ['D1'],
        totalPrice: 50000,
        qrData: 'QR',
        status: 'paid',
        createdAt: DateTime.now(),
      );

      expect(ticketFuture.remainingTimeLabel, contains('14:00 WIB'));
    });
  });

  group('TicketService PB-024 Offline & PB-025 Status Update Tests', () {
    test('updateTicketStatus should modify ticket in Hive cache', () async {
      final ticket = TicketModel(
        id: 'tkt-update-1',
        bookingCode: 'CNM-33333',
        userId: 'usr-offline',
        showtimeId: 'st-1',
        movieId: 500,
        movieTitle: 'Testing Offline Update',
        cinemaId: 'c1',
        cinemaName: 'Cinema Depok',
        cinemaAddress: 'Depok',
        hallName: 'Studio 2',
        experience: 'Regular 2D',
        showDate: '2026-11-10',
        showTime: '16:00',
        seats: ['F1'],
        totalPrice: 45000,
        qrData: 'CINEMATE://checkin?code=CNM-33333',
        status: 'paid',
        createdAt: DateTime.now(),
      );

      await storage.addTicketToCache(ticket.toJson());

      // Verifikasi awal tersimpan
      final cachedInitial = await storage.getCachedTickets();
      expect(cachedInitial, isNotNull);
      expect(cachedInitial!.any((t) => t['id'] == 'tkt-update-1'), isTrue);

      // Ubah status ke 'used'
      final updated = await ticketService.updateTicketStatus(
        ticketId: 'tkt-update-1',
        newStatus: 'used',
      );

      expect(updated, isNotNull);
      expect(updated!.status, 'used');
      expect(updated.isTicketHistory, isTrue);

      // Verifikasi pembacaan ulang dari Hive cache
      final cachedAfter = await storage.getCachedTickets();
      final updatedInCache =
          cachedAfter!.firstWhere((t) => t['id'] == 'tkt-update-1');
      expect(updatedInCache['status'], 'used');
    });

    test(
        'getUserTicketsWithMeta should return offline indicator and cachedAt timestamp',
        () async {
      final result = await ticketService.getUserTicketsWithMeta();
      expect(result.tickets, isNotEmpty);
      expect(result.isOffline, isTrue);
      expect(result.cachedAt, isNotNull);
    });
  });

  group('TicketsController PB-025 Separation & Search Tests', () {
    test('TicketsController should separate active tickets and history tickets',
        () async {
      // Siapkan 1 tiket aktif di masa depan dan 1 tiket lampau
      final active = TicketModel(
        id: 'tkt-ctrl-active',
        bookingCode: 'CNM-44444',
        userId: 'usr-1',
        showtimeId: 'st-1',
        movieId: 101,
        movieTitle: 'Avengers: Secret Wars',
        cinemaId: 'c1',
        cinemaName: 'Metro Cinema',
        cinemaAddress: 'Jakarta',
        hallName: 'Studio 1',
        experience: 'IMAX 3D',
        showDate: '2099-05-01',
        showTime: '19:00',
        seats: ['E1', 'E2'],
        totalPrice: 150000,
        qrData: 'QR-ACTIVE',
        status: 'paid',
        createdAt: DateTime.now(),
      );

      final history = TicketModel(
        id: 'tkt-ctrl-history',
        bookingCode: 'CNM-55555',
        userId: 'usr-1',
        showtimeId: 'st-2',
        movieId: 102,
        movieTitle: 'Oppenheimer',
        cinemaId: 'c2',
        cinemaName: 'Bintang Cinema',
        cinemaAddress: 'Jakarta',
        hallName: 'Studio 3',
        experience: 'Regular 2D',
        showDate: '2023-08-01',
        showTime: '13:00',
        seats: ['F5'],
        totalPrice: 40000,
        qrData: 'QR-HISTORY',
        status: 'used',
        createdAt: DateTime.now(),
      );

      await storage.clearTicketsCache();
      await storage.addTicketToCache(active.toJson());
      await storage.addTicketToCache(history.toJson());

      final controller = TicketsController();
      await controller.loadTickets();

      expect(controller.activeTickets.length, 1);
      expect(controller.activeTickets.first.bookingCode, 'CNM-44444');

      expect(controller.historyTickets.length, 1);
      expect(controller.historyTickets.first.bookingCode, 'CNM-55555');

      // Test fitur search
      controller.updateSearch('Avengers');
      expect(controller.displayedActiveTickets.length, 1);
      expect(controller.displayedHistoryTickets.length, 0);

      controller.updateSearch('Oppenheimer');
      expect(controller.displayedActiveTickets.length, 0);
      expect(controller.displayedHistoryTickets.length, 1);

      controller.updateSearch('');
      expect(controller.displayedActiveTickets.length, 1);
      expect(controller.displayedHistoryTickets.length, 1);
    });
  });
}
