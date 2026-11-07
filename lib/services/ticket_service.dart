// lib/services/ticket_service.dart
// Service untuk manajemen E-Ticket, QR Code, dan persistensi Supabase & Hive (PB-022, PB-023)

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_order_model.dart';
import '../models/ticket_model.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  final SupabaseService _supabase = SupabaseService();
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();

  /// Menghasilkan kode booking unik dengan format "CNM-XXXXX" (5 digit angka acak)
  static String generateBookingCode() {
    final randomNum = 10000 + Random().nextInt(90000);
    return 'CNM-$randomNum';
  }

  /// Membuat format payload data QR Code untuk check-in bioskop
  static String generateQrPayload(String bookingCode, String movieTitle, String showDate, String showTime, List<String> seats) {
    return 'CINEMATE:$bookingCode:$showDate:$showTime:${seats.join(",")}';
  }

  /// Menyimpan transaksi pesanan tiket ke Supabase & Hive cache (PB-022, PB-023)
  Future<TicketModel> createBooking({
    required BookingOrderModel order,
    required String userId,
  }) async {
    final bookingId = _uuid.v4();
    final bookingCode = generateBookingCode();
    final qrData = generateQrPayload(
      bookingCode,
      order.movie.title,
      order.showtime.showDate,
      order.showtime.showTime,
      order.selectedSeats,
    );

    final ticket = TicketModel(
      id: bookingId,
      bookingCode: bookingCode,
      userId: userId.isNotEmpty ? userId : 'usr-guest',
      showtimeId: order.showtime.id,
      movieId: order.movie.id,
      movieTitle: order.movie.title,
      posterPath: order.movie.posterPath,
      backdropPath: order.movie.backdropPath,
      cinemaId: order.cinema.id,
      cinemaName: order.cinema.name,
      cinemaAddress: order.cinema.address,
      hallName: order.showtime.hallName,
      experience: order.showtime.experience,
      showDate: order.showtime.showDate,
      showTime: order.showtime.showTime,
      seats: List<String>.from(order.selectedSeats),
      totalPrice: order.totalAmount,
      qrData: qrData,
      status: 'paid',
      paymentMethod: order.paymentMethod ?? 'QRIS Bersama',
      paymentReference: order.paymentReference ?? 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    // 1. Simpan ke Hive box 'tickets_cache' (Persistensi lokal instan / offline-first)
    try {
      await _storage.addTicketToCache(ticket.toJson());
      debugPrint('[TicketService] Berhasil menyimpan tiket ${ticket.bookingCode} ke Hive cache.');
    } catch (e) {
      debugPrint('[TicketService] Error menyimpan ke Hive cache: $e');
    }

    // 2. Simpan ke database Supabase (tabel bookings & booking_seats)
    try {
      if (_supabase.client.auth.currentSession != null || userId.isNotEmpty) {
        await _supabase.client.from('bookings').insert({
          'id': bookingId,
          'user_id': userId,
          'showtime_id': order.showtime.id,
          'booking_code': bookingCode,
          'status': 'paid',
          'total_price': order.totalAmount,
          'qr_data': qrData,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Insert kursi ke booking_seats
        final seatsPayload = order.selectedSeats.map((seat) {
          return {
            'id': _uuid.v4(),
            'booking_id': bookingId,
            'seat_label': seat,
          };
        }).toList();

        if (seatsPayload.isNotEmpty) {
          await _supabase.client.from('booking_seats').insert(seatsPayload);
        }
        debugPrint('[TicketService] Berhasil menyimpan tiket ${ticket.bookingCode} ke Supabase.');
      }
    } catch (e) {
      debugPrint('[TicketService] Supabase insert warning (offline/mock mode): $e');
    }

    return ticket;
  }

  /// Mengambil semua tiket milik pengguna dari Supabase / Hive cache
  Future<List<TicketModel>> getUserTickets({String? userId, bool forceRefresh = false}) async {
    // 1. Periksa cache Hive terlebih dahulu
    if (!forceRefresh) {
      try {
        final cached = await _storage.getCachedTickets();
        if (cached != null && cached.isNotEmpty) {
          final list = cached.map((e) => TicketModel.fromJson(e)).toList();
          return list;
        }
      } catch (e) {
        debugPrint('[TicketService] Error reading Hive ticket cache: $e');
      }
    }

    // 2. Coba fetch online dari Supabase
    try {
      final response = await _supabase.client
          .from('bookings')
          .select('*, booking_seats(seat_label)')
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        final tickets = response.map((row) {
          final seatsList = (row['booking_seats'] as List<dynamic>?)
                  ?.map((s) => s['seat_label']?.toString() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              [];

          return TicketModel(
            id: row['id']?.toString() ?? '',
            bookingCode: row['booking_code']?.toString() ?? 'CNM-00000',
            userId: row['user_id']?.toString() ?? '',
            showtimeId: row['showtime_id']?.toString() ?? '',
            movieId: 1,
            movieTitle: 'Bioskop Cinemate',
            cinemaId: 'cin-1',
            cinemaName: 'Metro Cinema Senayan',
            cinemaAddress: 'Jakarta Selatan',
            hallName: 'Studio 1',
            experience: 'Regular 2D',
            showDate: '2026-11-07',
            showTime: '14:00',
            seats: seatsList,
            totalPrice: row['total_price'] as int? ?? 50000,
            qrData: row['qr_data']?.toString() ?? '',
            status: row['status']?.toString() ?? 'paid',
            createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
          );
        }).toList();

        // Simpan ke Hive cache
        await _storage.cacheTickets(tickets.map((t) => t.toJson()).toList());
        return tickets;
      }
    } catch (e) {
      debugPrint('[TicketService] Supabase tickets fetch info: $e');
    }

    // 3. Fallback cache Hive
    try {
      final cached = await _storage.getCachedTickets();
      if (cached != null && cached.isNotEmpty) {
        return cached.map((e) => TicketModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('[TicketService] Fallback reading Hive cache error: $e');
    }

    // 4. Fallback data seed awal jika cache dan server belum ada data
    return [];
  }

  /// Memfilter tiket yang masih aktif (belum lewat jadwalnya)
  Future<List<TicketModel>> getActiveTickets({String? userId, bool forceRefresh = false}) async {
    final all = await getUserTickets(userId: userId, forceRefresh: forceRefresh);
    return all.where((t) => t.isActive).toList();
  }

  /// Memfilter riwayat tiket (tiket yang sudah selesai ditonton / kedaluwarsa)
  Future<List<TicketModel>> getHistoryTickets({String? userId, bool forceRefresh = false}) async {
    final all = await getUserTickets(userId: userId, forceRefresh: forceRefresh);
    return all.where((t) => !t.isActive).toList();
  }
}
