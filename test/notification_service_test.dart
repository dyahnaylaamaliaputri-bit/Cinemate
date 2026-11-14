// test/notification_service_test.dart
// Unit tests untuk Epic Notifikasi Lokal & Pengingat Jadwal (PB-056 s.d. PB-060)

import 'package:flutter_test/flutter_test.dart';
import 'package:cinemate/models/fnb_order_model.dart';
import 'package:cinemate/models/ticket_model.dart';
import 'package:cinemate/services/notification_service.dart';
import 'package:cinemate/services/storage_service.dart';
import 'package:cinemate/controllers/preference_controller.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationService notifService;
  late StorageService storageService;

  setUp(() async {
    Get.reset();
    storageService = StorageService();
    // Pastikan preferensi default aktif (true)
    await storageService.setNotifBooking(true);
    await storageService.setNotifReminder(true);
    await storageService.setNotifFnb(true);
    await storageService.setNotifPromo(true);

    notifService = NotificationService.instance;
    await notifService.initialize();
    notifService.dispatchedNotifications.clear();
    notifService.scheduledReminders.clear();
  });

  group('PB-056: Notifikasi Konfirmasi Pemesanan (Tiket & F&B)', () {
    test('Mengirim notifikasi instan saat booking tiket bioskop berhasil', () async {
      final ticket = TicketModel(
        id: 'tkt-test-001',
        bookingCode: 'CNM-88991',
        userId: 'usr-123',
        showtimeId: 'st-01',
        movieId: 101,
        movieTitle: 'Inception Remastered',
        cinemaId: 'cinema-01',
        cinemaName: 'Grand Indonesia CGV',
        cinemaAddress: 'Jl. M.H. Thamrin No.1',
        hallName: 'Studio 1',
        experience: 'IMAX Laser',
        showDate: '2026-11-20',
        showTime: '19:30',
        seats: ['F5', 'F6'],
        totalPrice: 120000,
        qrData: 'QR-INCEPTION-001',
        createdAt: DateTime.now(),
      );

      final result = await notifService.showTicketConfirmation(ticket);

      expect(result, isTrue);
      expect(notifService.dispatchedNotifications.length, 1);

      final dispatched = notifService.dispatchedNotifications.first;
      expect(dispatched['channel'], NotificationService.channelBookings);
      expect(dispatched['title'], contains('Inception Remastered'));
      expect(dispatched['body'], contains('CNM-88991'));
      expect(dispatched['body'], contains('Grand Indonesia CGV'));
      expect(dispatched['body'], contains('F5, F6'));
      expect(dispatched['payload'], contains('tkt-test-001'));
      expect(dispatched['payload'], contains('ticket_confirmation'));
    });

    test('Mengirim notifikasi instan saat checkout pesanan F&B berhasil', () async {
      final fnbOrder = FnbOrderModel(
        id: 'fnb-test-001',
        userId: 'usr-123',
        cinemaId: 'cinema-01',
        cinemaName: 'Grand Indonesia CGV',
        pickupCode: 'FNB-77210',
        status: 'processing',
        pickupMethod: 'counter',
        subtotal: 65000,
        totalPrice: 67000,
        paymentMethod: 'GoPay',
        createdAt: DateTime.now(),
        items: [
          const FnbOrderItemModel(
            fnbItemId: 'pop-01',
            name: 'Caramel Popcorn Large',
            price: 45000,
            quantity: 1,
            subtotal: 45000,
          ),
          const FnbOrderItemModel(
            fnbItemId: 'bev-01',
            name: 'Coca Cola Zero',
            price: 20000,
            quantity: 1,
            subtotal: 20000,
          ),
        ],
      );

      final result = await notifService.showFnbConfirmation(fnbOrder);

      expect(result, isTrue);
      expect(notifService.dispatchedNotifications.length, 1);

      final dispatched = notifService.dispatchedNotifications.first;
      expect(dispatched['channel'], NotificationService.channelFnb);
      expect(dispatched['title'], contains('FNB-77210'));
      expect(dispatched['body'], contains('Grand Indonesia CGV'));
      expect(dispatched['body'], contains('Caramel Popcorn Large'));
      expect(dispatched['payload'], contains('fnb-test-001'));
      expect(dispatched['payload'], contains('fnb_confirmation'));
    });
  });

  group('PB-057: Notifikasi Pengingat Jadwal Film Terjadwal (H-2 Jam & H-30 Menit)', () {
    test('Menjadwalkan alarm notifikasi H-2 jam dan H-30 menit untuk film di masa depan', () async {
      // Buat jadwal 5 jam dari sekarang
      final futureDate = DateTime.now().add(const Duration(hours: 5));
      final dateStr =
          '${futureDate.year.toString().padLeft(4, '0')}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${futureDate.hour.toString().padLeft(2, '0')}:${futureDate.minute.toString().padLeft(2, '0')}';

      final ticket = TicketModel(
        id: 'tkt-future-01',
        bookingCode: 'CNM-99001',
        userId: 'usr-123',
        showtimeId: 'st-02',
        movieId: 202,
        movieTitle: 'Interstellar: 10th Anniversary',
        cinemaId: 'cinema-01',
        cinemaName: 'Central Park XXI',
        cinemaAddress: 'Jl. Letjen S. Parman',
        hallName: 'IMAX 1',
        experience: 'IMAX',
        showDate: dateStr,
        showTime: timeStr,
        seats: ['E8', 'E9'],
        totalPrice: 150000,
        qrData: 'QR-INTERSTELLAR',
        createdAt: DateTime.now(),
      );

      final scheduledIds = await notifService.scheduleTicketReminders(ticket);

      // Harusnya terjadwal 2 pengingat: H-2 jam dan H-30 menit
      expect(scheduledIds.length, 2);
      expect(notifService.scheduledReminders.length, 2);

      final rem2h = notifService.scheduledReminders
          .firstWhere((r) => r['type'] == 'reminder_2h');
      final rem30m = notifService.scheduledReminders
          .firstWhere((r) => r['type'] == 'reminder_30m');

      expect(rem2h['ticketId'], 'tkt-future-01');
      expect(rem2h['title'], contains('2 Jam Lagi'));
      expect(rem30m['ticketId'], 'tkt-future-01');
      expect(rem30m['title'], contains('30 Menit Lagi'));

      final date2h = rem2h['scheduledDate'] as DateTime;
      final date30m = rem30m['scheduledDate'] as DateTime;
      expect(date2h.isBefore(date30m), isTrue);
    });

    test('Hanya menjadwalkan H-30 menit jika film tayang kurang dari 2 jam lagi', () async {
      // Buat jadwal 1 jam dari sekarang
      final futureDate = DateTime.now().add(const Duration(minutes: 60));
      final dateStr =
          '${futureDate.year.toString().padLeft(4, '0')}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${futureDate.hour.toString().padLeft(2, '0')}:${futureDate.minute.toString().padLeft(2, '0')}';

      final ticket = TicketModel(
        id: 'tkt-1hour-01',
        bookingCode: 'CNM-1HR',
        userId: 'usr-123',
        showtimeId: 'st-03',
        movieId: 203,
        movieTitle: 'Oppenheimer',
        cinemaId: 'cinema-01',
        cinemaName: 'Plaza Senayan XXI',
        cinemaAddress: 'Plaza Senayan',
        hallName: 'Studio 2',
        experience: 'Regular 2D',
        showDate: dateStr,
        showTime: timeStr,
        seats: ['A1'],
        totalPrice: 50000,
        qrData: 'QR-OPP',
        createdAt: DateTime.now(),
      );

      final scheduledIds = await notifService.scheduleTicketReminders(ticket);

      // Hanya pengingat H-30 menit yang terjadwal karena H-2 jam sudah lewat
      expect(scheduledIds.length, 1);
      expect(notifService.scheduledReminders.first['type'], 'reminder_30m');
    });

    test('Tidak menjadwalkan notifikasi jika jadwal film sudah lewat di masa lalu', () async {
      final pastDate = DateTime.now().subtract(const Duration(hours: 3));
      final dateStr =
          '${pastDate.year.toString().padLeft(4, '0')}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${pastDate.hour.toString().padLeft(2, '0')}:${pastDate.minute.toString().padLeft(2, '0')}';

      final ticket = TicketModel(
        id: 'tkt-past-01',
        bookingCode: 'CNM-PAST',
        userId: 'usr-123',
        showtimeId: 'st-04',
        movieId: 204,
        movieTitle: 'The Dark Knight',
        cinemaId: 'cinema-01',
        cinemaName: 'Mall Kelapa Gading',
        cinemaAddress: 'MKG',
        hallName: 'Studio 3',
        experience: 'Regular 2D',
        showDate: dateStr,
        showTime: timeStr,
        seats: ['B2'],
        totalPrice: 50000,
        qrData: 'QR-TDK',
        createdAt: DateTime.now(),
      );

      final scheduledIds = await notifService.scheduleTicketReminders(ticket);
      expect(scheduledIds, isEmpty);
      expect(notifService.scheduledReminders, isEmpty);
    });

    test('Membatalkan pengingat film yang terjadwal berdasarkan ticketId', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 4));
      final dateStr =
          '${futureDate.year.toString().padLeft(4, '0')}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${futureDate.hour.toString().padLeft(2, '0')}:${futureDate.minute.toString().padLeft(2, '0')}';

      final ticket = TicketModel(
        id: 'tkt-to-cancel',
        bookingCode: 'CNM-CANCEL',
        userId: 'usr-123',
        showtimeId: 'st-05',
        movieId: 205,
        movieTitle: 'Dune: Part Two',
        cinemaId: 'cinema-01',
        cinemaName: 'Grand Indonesia',
        cinemaAddress: 'GI',
        hallName: 'Studio 1',
        experience: 'IMAX',
        showDate: dateStr,
        showTime: timeStr,
        seats: ['D4'],
        totalPrice: 75000,
        qrData: 'QR-DUNE',
        createdAt: DateTime.now(),
      );

      await notifService.scheduleTicketReminders(ticket);
      expect(notifService.scheduledReminders.length, 2);

      // Batalkan pengingat tiket
      await notifService.cancelTicketReminders('tkt-to-cancel');
      expect(notifService.scheduledReminders, isEmpty);
    });
  });

  group('PB-058: Pengaturan Izin & Preferensi Notifikasi di Profil', () {
    test('Menonaktifkan notifBooking mencegah pengiriman notifikasi pemesanan', () async {
      await storageService.setNotifBooking(false);

      final ticket = TicketModel(
        id: 'tkt-pref-01',
        bookingCode: 'CNM-PREF',
        userId: 'usr-123',
        showtimeId: 'st-06',
        movieId: 101,
        movieTitle: 'Movie Test',
        cinemaId: 'c-01',
        cinemaName: 'Cinema Test',
        cinemaAddress: 'Addr',
        hallName: 'Studio 1',
        experience: '2D',
        showDate: '2026-11-20',
        showTime: '15:00',
        seats: ['A1'],
        totalPrice: 50000,
        qrData: 'QR',
        createdAt: DateTime.now(),
      );

      final res = await notifService.showTicketConfirmation(ticket);
      expect(res, isFalse);
      expect(notifService.dispatchedNotifications, isEmpty);
    });

    test('Menonaktifkan notifReminder mencegah penjadwalan alarm tayang', () async {
      await storageService.setNotifReminder(false);

      final futureDate = DateTime.now().add(const Duration(hours: 4));
      final dateStr =
          '${futureDate.year.toString().padLeft(4, '0')}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${futureDate.hour.toString().padLeft(2, '0')}:${futureDate.minute.toString().padLeft(2, '0')}';

      final ticket = TicketModel(
        id: 'tkt-pref-02',
        bookingCode: 'CNM-REM-OFF',
        userId: 'usr-123',
        showtimeId: 'st-07',
        movieId: 101,
        movieTitle: 'Movie Test',
        cinemaId: 'c-01',
        cinemaName: 'Cinema Test',
        cinemaAddress: 'Addr',
        hallName: 'Studio 1',
        experience: '2D',
        showDate: dateStr,
        showTime: timeStr,
        seats: ['A1'],
        totalPrice: 50000,
        qrData: 'QR',
        createdAt: DateTime.now(),
      );

      final scheduled = await notifService.scheduleTicketReminders(ticket);
      expect(scheduled, isEmpty);
      expect(notifService.scheduledReminders, isEmpty);
    });

    test('PreferenceController bereaksi terhadap toggle switch notifikasi', () async {
      final prefController = Get.put(PreferenceController());

      expect(prefController.notifBooking.value, isTrue);
      expect(prefController.notifReminder.value, isTrue);
      expect(prefController.notifFnb.value, isTrue);
      expect(prefController.notifPromo.value, isTrue);

      prefController.setNotifBooking(false);
      prefController.setNotifReminder(false);
      prefController.setNotifFnb(false);
      prefController.setNotifPromo(false);

      expect(prefController.notifBooking.value, isFalse);
      expect(prefController.notifReminder.value, isFalse);
      expect(prefController.notifFnb.value, isFalse);
      expect(prefController.notifPromo.value, isFalse);

      expect(storageService.notifBooking, isFalse);
      expect(storageService.notifReminder, isFalse);
      expect(storageService.notifFnb, isFalse);
      expect(storageService.notifPromo, isFalse);
    });
  });

  group('PB-059: Notifikasi Pengingat Pesanan F&B Siap Diambil', () {
    test('Mengirim notifikasi saat pesanan siap diambil di counter concession', () async {
      final fnbOrder = FnbOrderModel(
        id: 'fnb-ready-01',
        userId: 'usr-123',
        cinemaId: 'cinema-01',
        cinemaName: 'Senayan City XXI',
        pickupCode: 'FNB-99882',
        status: 'ready',
        pickupMethod: 'counter',
        subtotal: 50000,
        totalPrice: 52000,
        paymentMethod: 'BCA VA',
        createdAt: DateTime.now(),
        items: [
          const FnbOrderItemModel(
            fnbItemId: 'combo-1',
            name: 'Combo Solo Popcorn + Cola',
            price: 50000,
            quantity: 1,
            subtotal: 50000,
          ),
        ],
      );

      final result = await notifService.showFnbOrderReady(fnbOrder);

      expect(result, isTrue);
      expect(notifService.dispatchedNotifications.length, 1);

      final dispatched = notifService.dispatchedNotifications.first;
      expect(dispatched['channel'], NotificationService.channelFnb);
      expect(dispatched['title'], contains('Siap Diambil'));
      expect(dispatched['body'], contains('FNB-99882'));
      expect(dispatched['body'], contains('Counter Concession'));
      expect(dispatched['body'], contains('Senayan City XXI'));
      expect(dispatched['payload'], contains('ready'));
    });

    test('Mengirim notifikasi saat pesanan delivery sedang diantar ke kursi studio', () async {
      final fnbOrder = FnbOrderModel(
        id: 'fnb-ready-02',
        userId: 'usr-123',
        cinemaId: 'cinema-01',
        cinemaName: 'Senayan City XXI',
        pickupCode: 'FNB-DELIV-1',
        status: 'ready',
        pickupMethod: 'delivery',
        studioNumber: 'Studio 1',
        seatNumber: 'D4',
        subtotal: 50000,
        totalPrice: 52000,
        paymentMethod: 'ShopeePay',
        createdAt: DateTime.now(),
        items: [
          const FnbOrderItemModel(
            fnbItemId: 'nachos-1',
            name: 'Crispy Beef Nachos',
            price: 50000,
            quantity: 1,
            subtotal: 50000,
          ),
        ],
      );

      final result = await notifService.showFnbOrderReady(fnbOrder);

      expect(result, isTrue);
      final dispatched = notifService.dispatchedNotifications.first;
      expect(dispatched['title'], contains('Sedang Diantar'));
      expect(dispatched['body'], contains('Studio 1'));
      expect(dispatched['body'], contains('D4'));
    });

    test('Menolak pengiriman notifikasi F&B jika notifFnb dinonaktifkan', () async {
      await storageService.setNotifFnb(false);

      final fnbOrder = FnbOrderModel(
        id: 'fnb-ready-03',
        userId: 'usr-123',
        cinemaId: 'cinema-01',
        cinemaName: 'Senayan City XXI',
        pickupCode: 'FNB-BLOCKED',
        status: 'ready',
        pickupMethod: 'counter',
        subtotal: 30000,
        totalPrice: 32000,
        paymentMethod: 'OVO',
        createdAt: DateTime.now(),
        items: [],
      );

      final result = await notifService.showFnbOrderReady(fnbOrder);
      expect(result, isFalse);
      expect(notifService.dispatchedNotifications, isEmpty);
    });
  });

  group('PB-060: Notifikasi Penawaran Promo F&B Mingguan', () {
    test('Mengirim simulasi notifikasi promosi mingguan penonton bioskop', () async {
      final result = await notifService.showWeeklyPromo(
        title: 'Diskon Spesial 25% Popcorn!',
        message: 'Gunakan kode promo POPCORN25 untuk nonton seru hari ini.',
      );

      expect(result, isTrue);
      expect(notifService.dispatchedNotifications.length, 1);

      final dispatched = notifService.dispatchedNotifications.first;
      expect(dispatched['channel'], NotificationService.channelPromo);
      expect(dispatched['title'], contains('Diskon Spesial 25%'));
      expect(dispatched['body'], contains('POPCORN25'));
      expect(dispatched['payload'], contains('weekly_promo'));
    });

    test('Menolak pengiriman promo jika preferensi notifPromo dinonaktifkan', () async {
      await storageService.setNotifPromo(false);

      final result = await notifService.showWeeklyPromo();

      expect(result, isFalse);
      expect(notifService.dispatchedNotifications, isEmpty);
    });
  });
}
