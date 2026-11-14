// test/sync_hardening_test.dart
// Unit tests untuk Epic Sinkronisasi Data & Hardening Kualitas (PB-066, PB-067)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/services/storage_service.dart';
import 'package:cinemate/services/sync_service.dart';
import 'package:cinemate/services/ticket_service.dart';
import 'package:cinemate/services/fnb_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;
  late SyncService syncService;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => tempDir.path,
    );
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    Get.reset();
    storage = StorageService();
    await storage.clearTicketsCache();

    syncService = SyncService(
      storage: storage,
      ticketService: TicketService(),
      fnbService: FnbService(),
    );
    Get.put(syncService);
  });

  tearDown(() {
    Get.reset();
  });

  group('PB-066: Sinkronisasi Otomatis Data Lokal & Cloud (Hive -> Supabase)', () {
    test('Mendeteksi status konektivitas perangkat secara reaktif', () async {
      syncService.isOnline.value = true;
      expect(syncService.isOnline.value, isTrue);

      syncService.isOnline.value = false;
      expect(syncService.isOnline.value, isFalse);
    });

    test('Menolak sinkronisasi ketika perangkat dalam kondisi offline', () async {
      syncService.isOnline.value = false;

      final result = await syncService.syncOfflineData(forceOnline: false);

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('offline'));
      expect(syncService.isSyncing.value, isFalse);
    });

    test('Menghitung data offline yang belum tersinkronkan dengan akurat', () async {
      // Simpan 2 tiket offline ke Hive
      final ticket1 = {
        'id': 'tkt-sync-001',
        'booking_code': 'CNM-11223',
        'user_id': 'usr-01',
        'movie_id': 101,
        'movie_title': 'Avatar 3',
        'cinema_id': 'cin-01',
        'cinema_name': 'Grand Indonesia',
        'hall_name': 'Studio 1',
        'experience': 'IMAX',
        'show_date': '2026-11-20',
        'show_time': '19:00',
        'seats': ['E5', 'E6'],
        'total_price': 150000,
        'status': 'paid',
        'qr_data': 'QR-11223',
        'is_synced': false,
      };

      final ticket2 = {
        'id': 'tkt-sync-002',
        'booking_code': 'CNM-44556',
        'user_id': 'usr-01',
        'movie_id': 102,
        'movie_title': 'Gladiator 2',
        'cinema_id': 'cin-01',
        'cinema_name': 'Grand Indonesia',
        'hall_name': 'Studio 2',
        'experience': 'Regular 2D',
        'show_date': '2026-11-20',
        'show_time': '20:00',
        'seats': ['A1'],
        'total_price': 50000,
        'status': 'paid',
        'qr_data': 'QR-44556',
        'is_synced': true, // Sudah synced
      };

      await storage.cacheTickets([ticket1, ticket2]);
      await syncService.updateUnsyncedCounts();

      // Hanya ticket1 yang belum synced
      expect(syncService.unsyncedTicketsCount.value, 1);
      expect(syncService.totalUnsynced, 1);
    });

    test('Menyinkronkan data tiket offline dan menandai status is_synced: true', () async {
      final ticket = {
        'id': 'tkt-to-sync',
        'booking_code': 'CNM-SYNC-01',
        'user_id': 'usr-02',
        'movie_id': 201,
        'movie_title': 'Interstellar',
        'cinema_id': 'cin-02',
        'cinema_name': 'Plaza Senayan',
        'hall_name': 'Studio 1',
        'experience': 'IMAX',
        'show_date': '2026-11-22',
        'show_time': '16:00',
        'seats': ['C3'],
        'total_price': 75000,
        'status': 'paid',
        'qr_data': 'QR-INTER',
        'is_synced': false,
      };

      await storage.cacheTickets([ticket]);
      await syncService.updateUnsyncedCounts();
      expect(syncService.unsyncedTicketsCount.value, 1);

      // Jalankan sinkronisasi
      syncService.isOnline.value = true;
      final result = await syncService.syncOfflineData(forceOnline: true);

      expect(result.isSuccess, isTrue);
      expect(result.syncedTickets, 1);
      expect(syncService.lastSyncTime.value, isNotNull);

      // Verifikasi di cache bahwa tiket telah ditandai is_synced: true
      final cached = await storage.getCachedTickets();
      expect(cached?.first['is_synced'], isTrue);
      expect(cached?.first['synced_at'], isNotNull);
      expect(syncService.unsyncedTicketsCount.value, 0);
    });

    test('Pencegahan Duplikasi (Idempotency): Tidak menduplikasi data yang sudah tersinkronkan', () async {
      final ticket = {
        'id': 'tkt-idempotent-01',
        'booking_code': 'CNM-IDEM-01',
        'user_id': 'usr-03',
        'movie_id': 301,
        'movie_title': 'Oppenheimer',
        'cinema_id': 'cin-03',
        'cinema_name': 'Central Park',
        'hall_name': 'Studio 3',
        'experience': '2D',
        'show_date': '2026-11-25',
        'show_time': '13:00',
        'seats': ['D4'],
        'total_price': 50000,
        'status': 'paid',
        'qr_data': 'QR-OPP',
        'is_synced': false,
      };

      await storage.cacheTickets([ticket]);

      // Sync pertama: 1 tiket tersinkronkan
      final res1 = await syncService.syncOfflineData(forceOnline: true);
      expect(res1.syncedTickets, 1);

      // Sync kedua: tiket sudah is_synced == true, tidak boleh disinkronkan ulang
      final res2 = await syncService.syncOfflineData(forceOnline: true);
      expect(res2.syncedTickets, 0);

      final cached = await storage.getCachedTickets();
      expect(cached?.length, 1); // Jumlah tiket tetap 1, tidak ada duplikasi
    });
  });

  group('PB-067: Optimasi Cold Start & Hardening Kualitas', () {
    test('Verifikasi performa cold start inisialisasi aplikasi di bawah 4.0 detik (< 4000 ms)', () async {
      final duration = await syncService.measureStartupTime(() async {
        // Simulasi inisialisasi startup: Storage, Hive boxes, User Session & Sync check
        final storage = StorageService();
        await storage.getUserId();
        storage.getFavoriteGenres();
        await syncService.checkConnectivity();
        await syncService.updateUnsyncedCounts();
      });

      // Acceptance Criteria PB-067: Waktu cold start harus < 4 detik (4000 ms)
      expect(duration.inMilliseconds, lessThan(4000));
    });

    test('Crash Resistance Guard: Menangkap exception tak terduga dan mengembalikan nilai fallback', () async {
      // Operasi yang sengaja melempar error tak terduga
      final result = await syncService.executeProtected<String>(
        action: () async {
          throw Exception('Simulasi kegagalan parsing jaringan atau format korup');
        },
        fallback: 'FALLBACK_AMAN',
        operationName: 'NetworkFetchTest',
      );

      // Aplikasi tidak boleh crash, dan harus mengembalikan fallback aman
      expect(result, 'FALLBACK_AMAN');
    });

    test('Crash Resistance Guard: Mengembalikan hasil asli jika operasi sukses tanpa error', () async {
      final result = await syncService.executeProtected<int>(
        action: () async => 42,
        fallback: 0,
        operationName: 'SuccessOperationTest',
      );

      expect(result, 42);
    });

    test('Ketahanan terhadap data cache lokal yang korup (Corrupted JSON Cache Resilience)', () async {
      // Simpan data korup / format aneh ke cache tiket
      await storage.cacheTickets([
        {'id': null, 'corrupted_field': 'invalid_data'},
      ]);

      // Operasi pengambilan tiket tidak boleh crash
      final tickets = await storage.getCachedTickets();
      expect(tickets, isNotNull);
      expect(tickets?.length, 1);

      // Update sync count tidak boleh crash saat menghadapi format korup
      await expectLater(syncService.updateUnsyncedCounts(), completes);
    });
  });
}
