// lib/services/ticket_service.dart
// Service untuk manajemen pemesanan & e-ticket bioskop (PB-022 s.d. PB-025)

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_order_model.dart';
import '../models/ticket_model.dart';
import 'storage_service.dart';

class TicketService {
  TicketService._internal();
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;

  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();

  /// Mengakses Supabase client secara aman (offline-safe bila belum diinisialisasi)
  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Menghasilkan kode booking unik dengan format: CNM-XXXXX (5 digit acak)
  static String generateBookingCode() {
    final rand = Random();
    final number = rand.nextInt(90000) + 10000; // Rentang 10000..99999
    return 'CNM-$number';
  }

  /// Menghasilkan payload data untuk ditampilkan pada QR Code (PB-022)
  static String generateQrPayload(
    String bookingCode,
    String movieTitle,
    String showDate,
    String showTime,
    List<String> seats,
  ) {
    return 'CINEMATE:$bookingCode:$showDate:$showTime:${seats.join(',')}';
  }

  /// Membuat pesanan baru dan menerbitkan E-Ticket (PB-022, PB-023)
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
      showtimeId: order.showtime.id,
      userId: userId,
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
      seats: order.selectedSeats,
      totalPrice: order.totalAmount,
      status: 'paid',
      paymentMethod: order.paymentMethod,
      paymentReference: order.paymentReference,
      qrData: qrData,
      createdAt: DateTime.now(),
    );

    // 1. Simpan ke Hive cache lokal (PB-023, PB-024)
    try {
      await _storage.addTicketToCache(ticket.toJson());
      debugPrint('[TicketService] Berhasil menyimpan tiket ${ticket.bookingCode} ke Hive cache.');
    } catch (e) {
      debugPrint('[TicketService] Hive caching error: $e');
    }

    // 2. Simpan ke database Supabase (tabel bookings & booking_seats)
    final client = _supabaseClient;
    if (client != null) {
      try {
        if (client.auth.currentSession != null || userId.isNotEmpty) {
          await client.from('bookings').insert({
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
            await client.from('booking_seats').insert(seatsPayload);
          }
          debugPrint('[TicketService] Berhasil menyimpan tiket ${ticket.bookingCode} ke Supabase.');
        }
      } catch (e) {
        debugPrint('[TicketService] Supabase insert warning (offline/mock mode): $e');
      }
    }

    return ticket;
  }

  /// Mengambil semua tiket milik pengguna dari Supabase / Hive cache
  Future<List<TicketModel>> getUserTickets({String? userId, bool forceRefresh = false}) async {
    final meta = await getUserTicketsWithMeta(userId: userId, forceRefresh: forceRefresh);
    return meta.tickets;
  }

  /// Mengambil semua tiket beserta indikasi offline dan waktu cache (PB-024)
  Future<({List<TicketModel> tickets, bool isOffline, DateTime? cachedAt})> getUserTicketsWithMeta({
    String? userId,
    bool forceRefresh = false,
  }) async {
    // 1. Periksa cache Hive terlebih dahulu jika tidak force refresh
    if (!forceRefresh) {
      try {
        final cached = await _storage.getCachedTicketsWithMeta();
        if (cached.data != null && cached.data!.isNotEmpty) {
          final list = cached.data!.map((e) => TicketModel.fromJson(e)).toList();
          return (tickets: list, isOffline: true, cachedAt: cached.timestamp);
        }
      } catch (e) {
        debugPrint('[TicketService] Error reading Hive ticket cache: $e');
      }
    }

    // 2. Coba fetch online dari Supabase
    final client = _supabaseClient;
    if (client != null) {
      try {
        final response = await client
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
          return (tickets: tickets, isOffline: false, cachedAt: DateTime.now());
        }
      } catch (e) {
        debugPrint('[TicketService] Supabase tickets fetch info: $e');
      }
    }

    // 3. Fallback cache Hive saat koneksi internet / server bermasalah
    try {
      final cached = await _storage.getCachedTicketsWithMeta();
      if (cached.data != null && cached.data!.isNotEmpty) {
        final list = cached.data!.map((e) => TicketModel.fromJson(e)).toList();
        return (tickets: list, isOffline: true, cachedAt: cached.timestamp);
      }
    } catch (e) {
      debugPrint('[TicketService] Fallback reading Hive cache error: $e');
    }

    return (tickets: <TicketModel>[], isOffline: true, cachedAt: null);
  }

  /// Memperbarui status tiket (misal: 'used' atau 'expired') di Hive & Supabase (PB-024, PB-025)
  Future<TicketModel?> updateTicketStatus({
    required String ticketId,
    required String newStatus,
  }) async {
    final cached = await _storage.getCachedTickets() ?? [];
    final index = cached.indexWhere((t) => t['id'] == ticketId || t['booking_code'] == ticketId);
    TicketModel? updatedTicket;

    if (index >= 0) {
      final map = Map<String, dynamic>.from(cached[index]);
      map['status'] = newStatus;
      cached[index] = map;
      await _storage.cacheTickets(cached);
      updatedTicket = TicketModel.fromJson(map);
      debugPrint('[TicketService] Status tiket $ticketId berhasil diubah ke $newStatus di Hive cache.');
    }

    // Coba update juga ke Supabase jika online
    final client = _supabaseClient;
    if (client != null) {
      try {
        await client
            .from('bookings')
            .update({'status': newStatus})
            .eq('id', ticketId);
      } catch (e) {
        debugPrint('[TicketService] Supabase update warning: $e');
      }
    }

    return updatedTicket;
  }

  /// Memfilter tiket yang masih aktif (jadwal belum lewat & status bukan used/expired)
  Future<List<TicketModel>> getActiveTickets({String? userId, bool forceRefresh = false}) async {
    final all = await getUserTickets(userId: userId, forceRefresh: forceRefresh);
    return all.where((t) => t.isTicketActive).toList();
  }

  /// Memfilter riwayat tiket (jadwal sudah lewat atau status used/expired/cancelled)
  Future<List<TicketModel>> getHistoryTickets({String? userId, bool forceRefresh = false}) async {
    final all = await getUserTickets(userId: userId, forceRefresh: forceRefresh);
    return all.where((t) => t.isTicketHistory).toList();
  }
}
