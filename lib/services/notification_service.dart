// lib/services/notification_service.dart
// Service Notifikasi Lokal & Penjadwalan Pengingat (NTF — PB 12 / PB-056 s.d. PB-060)
// Fitur:
// - PB-056: Notifikasi Konfirmasi Pemesanan Tiket & F&B (Instan)
// - PB-057: Notifikasi Pengingat Jadwal Film Terjadwal (H-2 Jam & H-30 Menit)
// - PB-058: Pengaturan Izin & Preferensi Notifikasi di Profil
// - PB-059: Notifikasi Pengingat Pesanan F&B Siap Diambil (Ready di Counter)
// - PB-060: Notifikasi Penawaran Promo F&B & Film Baru Mingguan

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/ticket_model.dart';
import '../models/fnb_order_model.dart';
import 'storage_service.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StorageService _storage = StorageService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ── Channel IDs (Android Notification Channels) ───────────────────────────
  static const String channelBookings = 'cinemate_bookings';
  static const String channelReminders = 'cinemate_reminders';
  static const String channelFnb = 'cinemate_fnb';
  static const String channelPromo = 'cinemate_promo';

  // ── In-Memory Tracking untuk Verifikasi Unit Test & Manajemen Lokal ───────
  final List<Map<String, dynamic>> dispatchedNotifications = [];
  final List<Map<String, dynamic>> scheduledReminders = [];

  bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Inisialisasi plugin notifikasi & timezone engine
  Future<void> initialize() => init();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('[NotificationService] Timezone init info: $e');
    }

    if (_isTestEnvironment) {
      _isInitialized = true;
      return;
    }

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await requestPermissions();
      _isInitialized = true;
      debugPrint('[NotificationService] Notifikasi lokal berhasil diinisialisasi.');
    } catch (e) {
      debugPrint('[NotificationService] Inisialisasi plugin error (graceful fallback): $e');
      _isInitialized = true;
    }
  }

  /// Meminta izin notifikasi pada perangkat Android 13+ dan iOS
  Future<bool> requestPermissions() async {
    if (_isTestEnvironment) return true;

    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted =
            await androidImpl?.requestNotificationsPermission() ?? true;
        return granted;
      } else if (Platform.isIOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            true;
        return granted;
      }
    } catch (e) {
      debugPrint('[NotificationService] Request permission info: $e');
    }
    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notifikasi ditekan dengan payload: ${response.payload}');
  }

  // =========================================================================
  // 1. PB-056: NOTIFIKASI KONFIRMASI PEMESANAN (INSTAN)
  // =========================================================================

  /// Notifikasi instan saat pembayaran tiket berhasil (PB-056)
  Future<bool> showTicketConfirmation(TicketModel ticket) async {
    // Periksa preferensi pengguna (PB-058)
    if (!_storage.notifBooking) {
      debugPrint('[NotificationService] Notifikasi booking dinonaktifkan oleh pengguna.');
      return false;
    }

    final id = (ticket.id.hashCode.abs() % 100000);
    final title = 'Tiket Berhasil Dipesan: ${ticket.movieTitle} 🎉';
    final body =
        '${ticket.movieTitle} di ${ticket.cinemaName} (${ticket.hallName}), Kursi: ${ticket.seats.join(', ')}. Kode Booking: ${ticket.bookingCode}';
    final payload = jsonEncode({
      'type': 'ticket_confirmation',
      'ticketId': ticket.id,
      'bookingCode': ticket.bookingCode,
    });

    _recordDispatched(
      id: id,
      channel: channelBookings,
      title: title,
      body: body,
      payload: payload,
    );

    if (!_isTestEnvironment) {
      try {
        const androidDetails = AndroidNotificationDetails(
          channelBookings,
          'Konfirmasi Pemesanan Tiket',
          channelDescription: 'Notifikasi konfirmasi berhasil pesan tiket bioskop',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(sound: 'default'),
        );

        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: notificationDetails,
          payload: payload,
        );
      } catch (e) {
        debugPrint('[NotificationService] Gagal menampilkan notifikasi tiket: $e');
      }
    }

    return true;
  }

  /// Notifikasi instan saat pesanan F&B berhasil dibuat (PB-056)
  Future<bool> showFnbConfirmation(FnbOrderModel order) async {
    // Periksa preferensi pengguna (PB-058)
    if (!_storage.notifBooking) {
      debugPrint('[NotificationService] Notifikasi booking dinonaktifkan oleh pengguna.');
      return false;
    }

    final id = (order.id.hashCode.abs() % 100000) + 10;
    final title = 'Pesanan F&B Diterima! (${order.pickupCode}) 🍿🥤';
    final itemsSummary =
        order.items.map((e) => '${e.quantity}x ${e.name}').join(', ');
    final body =
        'Pesanan ${order.pickupCode} di ${order.cinemaName} ($itemsSummary) sedang disiapkan. Total: ${order.formattedTotalPrice}';
    final payload = jsonEncode({
      'type': 'fnb_confirmation',
      'orderId': order.id,
      'pickupCode': order.pickupCode,
    });

    _recordDispatched(
      id: id,
      channel: channelFnb,
      title: title,
      body: body,
      payload: payload,
    );

    if (!_isTestEnvironment) {
      try {
        const androidDetails = AndroidNotificationDetails(
          channelFnb,
          'Pemesanan Makanan (F&B)',
          channelDescription: 'Notifikasi konfirmasi pembelian F&B bioskop',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(sound: 'default'),
        );

        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: notificationDetails,
          payload: payload,
        );
      } catch (e) {
        debugPrint('[NotificationService] Gagal menampilkan notifikasi F&B: $e');
      }
    }

    return true;
  }

  // =========================================================================
  // 2. PB-057: PENGINGAT JADWAL FILM TERJADWAL (H-2 JAM & H-30 MENIT)
  // =========================================================================

  /// Menjadwalkan 2 pengingat otomatis sebelum film tayang:
  /// - H-2 Jam (120 menit sebelumnya)
  /// - H-30 Menit (30 menit sebelumnya)
  Future<List<int>> scheduleTicketReminders(TicketModel ticket) async {
    // Periksa preferensi pengguna (PB-058)
    if (!_storage.notifReminder) {
      debugPrint('[NotificationService] Pengingat jadwal dinonaktifkan oleh pengguna.');
      return [];
    }

    final scheduledIds = <int>[];
    final showDateTime = _parseTicketShowDateTime(ticket);
    final now = DateTime.now();

    final baseId = (ticket.id.hashCode.abs() % 100000);
    final id2Hours = baseId * 10 + 1;
    final id30Mins = baseId * 10 + 2;

    // 1. Pengingat H-2 Jam (120 Menit Sebelum Film)
    final time2HoursBefore =
        showDateTime.subtract(const Duration(minutes: 120));
    final title2Hours = 'Pengingat Film (2 Jam Lagi): ${ticket.movieTitle} ⏰';
    final body2Hours =
        'Film Anda akan dimulai dalam 2 jam (${ticket.showTime}) di ${ticket.cinemaName}. Siapkan perjalanan Anda!';

    if (time2HoursBefore.isAfter(now)) {
      _recordScheduled(
        id: id2Hours,
        ticketId: ticket.id,
        scheduledTime: time2HoursBefore,
        title: title2Hours,
        body: body2Hours,
        type: 'reminder_2h',
      );
      scheduledIds.add(id2Hours);

      if (!_isTestEnvironment) {
        await _scheduleLocalNotification(
          id: id2Hours,
          title: title2Hours,
          body: body2Hours,
          scheduledDate: time2HoursBefore,
          channel: channelReminders,
          channelName: 'Pengingat Jadwal Film',
          payload: jsonEncode({
            'type': 'showtime_reminder_2h',
            'ticketId': ticket.id,
            'bookingCode': ticket.bookingCode,
          }),
        );
      }
    }

    // 2. Pengingat H-30 Menit (30 Menit Sebelum Film)
    final time30MinsBefore =
        showDateTime.subtract(const Duration(minutes: 30));
    final title30Mins = 'Pengingat Film (30 Menit Lagi): ${ticket.movieTitle} 🎬';
    final body30Mins =
        'Film ${ticket.movieTitle} dimulai 30 menit lagi (${ticket.hallName}, Kursi: ${ticket.seats.join(', ')}). Tunjukkan tiket ${ticket.bookingCode} di pintu studio!';

    if (time30MinsBefore.isAfter(now)) {
      _recordScheduled(
        id: id30Mins,
        ticketId: ticket.id,
        scheduledTime: time30MinsBefore,
        title: title30Mins,
        body: body30Mins,
        type: 'reminder_30m',
      );
      scheduledIds.add(id30Mins);

      if (!_isTestEnvironment) {
        await _scheduleLocalNotification(
          id: id30Mins,
          title: title30Mins,
          body: body30Mins,
          scheduledDate: time30MinsBefore,
          channel: channelReminders,
          channelName: 'Pengingat Jadwal Film',
          payload: jsonEncode({
            'type': 'showtime_reminder_30m',
            'ticketId': ticket.id,
            'bookingCode': ticket.bookingCode,
          }),
        );
      }
    }

    return scheduledIds;
  }

  /// Membatalkan alarm pengingat jika tiket dibatalkan atau kadaluwarsa (PB-057)
  Future<void> cancelTicketReminders(String ticketId) async {
    final targets = scheduledReminders
        .where((r) => r['ticketId'] == ticketId)
        .toList();

    for (final reminder in targets) {
      final notifId = reminder['id'] as int;
      if (!_isTestEnvironment) {
        try {
          await _plugin.cancel(id: notifId);
        } catch (_) {}
      }
    }

    scheduledReminders.removeWhere((r) => r['ticketId'] == ticketId);
    debugPrint('[NotificationService] Berhasil membatalkan pengingat tiket $ticketId.');
  }

  // =========================================================================
  // 3. PB-059: NOTIFIKASI PESANAN F&B SIAP DIAMBIL (READY DI COUNTER)
  // =========================================================================

  /// Notifikasi saat pesanan F&B berubah status menjadi 'ready' (PB-059)
  Future<bool> showFnbOrderReady(FnbOrderModel order) async {
    // Periksa preferensi pengguna (PB-058)
    if (!_storage.notifFnb) {
      debugPrint('[NotificationService] Notifikasi F&B dinonaktifkan oleh pengguna.');
      return false;
    }

    final id = (order.id.hashCode.abs() % 100000) + 20;
    final bool isDelivery = order.pickupMethod == 'delivery';
    final title = isDelivery
        ? 'Pesanan F&B Sedang Diantar ke Kursi! 🍿🚴'
        : 'Pesanan F&B Siap Diambil di Counter! ✨🍿';
    final body = isDelivery
        ? 'Pesanan ${order.pickupCode} sedang diantar ke ${order.studioNumber ?? "Studio"} kursi ${order.seatNumber ?? ""}. Silakan tunggu di kursi Anda!'
        : 'Pesanan ${order.pickupCode} sudah siap! Silakan ambil di Counter Concession ${order.cinemaName}. Selamat menikmati film!';
    final payload = jsonEncode({
      'type': 'fnb_ready',
      'orderId': order.id,
      'pickupCode': order.pickupCode,
    });

    _recordDispatched(
      id: id,
      channel: channelFnb,
      title: title,
      body: body,
      payload: payload,
    );

    if (!_isTestEnvironment) {
      try {
        const androidDetails = AndroidNotificationDetails(
          channelFnb,
          'Pemesanan Makanan (F&B)',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(sound: 'default'),
        );

        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: notificationDetails,
          payload: payload,
        );
      } catch (e) {
        debugPrint('[NotificationService] Gagal menampilkan notifikasi F&B Ready: $e');
      }
    }

    return true;
  }

  // =========================================================================
  // 4. PB-060: NOTIFIKASI PENAWARAN PROMO F&B & FILM BARU MINGGUAN
  // =========================================================================

  /// Notifikasi simulasi promosi mingguan untuk engagement penonton (PB-060)
  Future<bool> showWeeklyPromo({
    String? title,
    String? message,
    String? promoTitle,
    String? promoBody,
  }) async {
    // Periksa preferensi pengguna (PB-058)
    if (!_storage.notifPromo) {
      debugPrint(
          '[NotificationService] Notifikasi promo dinonaktifkan oleh pengguna.');
      return false;
    }

    const id = 99901;
    final effectiveTitle =
        title ?? promoTitle ?? 'Promo Spesial Nonton Akhir Pekan! 🍿🥤';
    final effectiveBody = message ??
        promoBody ??
        'Dapatkan diskon Combo Popcorn Caramel + 2 Minuman Dingin hemat hingga 20%! Cek menu F&B bioskop sekarang.';
    final payload = jsonEncode({
      'type': 'weekly_promo',
      'promoCode': 'CINEMATE20',
    });

    _recordDispatched(
      id: id,
      channel: channelPromo,
      title: effectiveTitle,
      body: effectiveBody,
      payload: payload,
    );

    if (!_isTestEnvironment) {
      try {
        const androidDetails = AndroidNotificationDetails(
          channelPromo,
          'Promo & Penawaran Spesial',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        );
        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(),
        );

        await _plugin.show(
          id: id,
          title: effectiveTitle,
          body: effectiveBody,
          notificationDetails: notificationDetails,
          payload: payload,
        );
      } catch (e) {
        debugPrint(
            '[NotificationService] Gagal menampilkan notifikasi promo: $e');
      }
    }

    return true;
  }

  // =========================================================================
  // 5. HELPER METHODS & TESTABILITY
  // =========================================================================

  DateTime _parseTicketShowDateTime(TicketModel ticket) {
    try {
      final dateParts = ticket.showDate.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final timeClean = ticket.showTime.replaceAll(RegExp(r'[^\d:]'), '');
      final timeParts = timeClean.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      // Fallback: 3 jam dari sekarang
      return DateTime.now().add(const Duration(hours: 3));
    }
  }

  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channel,
    required String channelName,
    required String payload,
  }) async {
    try {
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      final androidDetails = AndroidNotificationDetails(
        channel,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(sound: 'default'),
      );

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] Schedule notification error: $e');
    }
  }

  void _recordDispatched({
    required int id,
    required String channel,
    required String title,
    required String body,
    required String payload,
  }) {
    dispatchedNotifications.add({
      'id': id,
      'channel': channel,
      'title': title,
      'body': body,
      'payload': payload,
      'timestamp': DateTime.now(),
    });
  }

  void _recordScheduled({
    required int id,
    required String ticketId,
    required DateTime scheduledTime,
    required String title,
    required String body,
    required String type,
  }) {
    scheduledReminders.add({
      'id': id,
      'ticketId': ticketId,
      'scheduledTime': scheduledTime,
      'scheduledDate': scheduledTime,
      'title': title,
      'body': body,
      'type': type,
    });
  }

  /// Bersihkan log memori saat pengujian unit test
  void resetForTesting() {
    dispatchedNotifications.clear();
    scheduledReminders.clear();
  }
}
