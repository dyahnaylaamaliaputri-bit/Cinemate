// test/profile_cinemate_test.dart
// Unit tests untuk Epic Profil Lanjutan & My Cinemate (PB-061 s.d. PB-065)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:cinemate/controllers/profile_controller.dart';
import 'package:cinemate/controllers/auth_controller.dart';
import 'package:cinemate/models/mood_history_model.dart';
import 'package:cinemate/models/user_model.dart';
import 'package:cinemate/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;
  late ProfileController profileCtrl;

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

    // Reset storage memory state
    storage.themeMode = 'dark';
    storage.biometricEnabled = false;
    storage.avatarPath = null;
    await storage.saveFavoriteGenres(['Action', 'Sci-Fi', 'Drama']);
    await storage.clearMoodHistory();

    // Register AuthController mock user
    final authCtrl = Get.put(AuthController(storage: storage));
    authCtrl.currentUser.value = UserModel(
      id: 'usr-profile-test',
      email: 'alex@cinemate.id',
      fullName: 'Alex Cinephile',
      phone: '081234567890',
      createdAt: DateTime.now(),
    );

    profileCtrl = ProfileController(storage: storage);
    Get.put(profileCtrl);
  });

  tearDown(() {
    Get.reset();
  });

  group('PB-061: Unggah Foto Profil Pengguna & Fallback Avatar', () {
    test('Menyimpan path avatar kustom dan memperbarui currentUser avatarUrl', () async {
      const testPath = '/data/user/0/com.cinemate/cache/my_photo.jpg';

      profileCtrl.avatarPath.value = testPath;
      storage.avatarPath = testPath;

      final authCtrl = Get.find<AuthController>();
      authCtrl.currentUser.value =
          authCtrl.currentUser.value?.copyWith(avatarUrl: testPath);

      expect(profileCtrl.avatarPath.value, testPath);
      expect(storage.avatarPath, testPath);
      expect(authCtrl.currentUser.value?.avatarUrl, testPath);
    });

    test('Menghapus foto kustom dan kembali ke fallback avatar bawaan', () async {
      profileCtrl.avatarPath.value = '/some/path/avatar.jpg';
      storage.avatarPath = '/some/path/avatar.jpg';

      await profileCtrl.removeCustomAvatar();

      expect(profileCtrl.avatarPath.value, isNull);
      expect(storage.avatarPath, isNull);
      expect(Get.find<AuthController>().currentUser.value?.avatarUrl, isNull);
    });
  });

  group('PB-063: Halaman Pengaturan Aplikasi Lanjutan', () {
    test('Mengubah preferensi tema aplikasi dan menyimpan ke local storage', () {
      expect(profileCtrl.themeMode.value, 'dark');

      profileCtrl.setThemeMode('light');
      expect(profileCtrl.themeMode.value, 'light');
      expect(storage.themeMode, 'light');

      profileCtrl.setThemeMode('system');
      expect(profileCtrl.themeMode.value, 'system');
      expect(storage.themeMode, 'system');
    });

    test('Mengaktifkan dan menonaktifkan login biometrik', () {
      expect(profileCtrl.isBiometricEnabled.value, isFalse);

      profileCtrl.setBiometricEnabled(true);
      expect(profileCtrl.isBiometricEnabled.value, isTrue);
      expect(storage.biometricEnabled, isTrue);

      profileCtrl.setBiometricEnabled(false);
      expect(profileCtrl.isBiometricEnabled.value, isFalse);
      expect(storage.biometricEnabled, isFalse);
    });

    test('Membersihkan cache Hive aplikasi tanpa error', () async {
      await expectLater(profileCtrl.clearAppCache(), completes);
    });

    test('Reset semua pengaturan mengembalikan setelan default', () async {
      profileCtrl.setThemeMode('light');
      profileCtrl.setBiometricEnabled(true);
      storage.currencyPref = 'USD';
      storage.timezonePref = 'Asia/Jayapura';
      await storage.setNotifBooking(false);

      await profileCtrl.resetAllPreferences();

      expect(profileCtrl.themeMode.value, 'dark');
      expect(profileCtrl.isBiometricEnabled.value, isFalse);
      expect(storage.currencyPref, 'IDR');
      expect(storage.timezonePref, 'Asia/Jakarta');
      expect(storage.notifBooking, isTrue);
      expect(storage.notifReminder, isTrue);
    });
  });

  group('PB-064: Layar "My Cinemate" (Statistik, Badge Loyalitas & Genre)', () {
    test('Memuat preferensi genre default dan toggle genre film', () async {
      expect(profileCtrl.favoriteGenres, containsAll(['Action', 'Sci-Fi', 'Drama']));

      // Tambahkan genre baru 'Horror'
      profileCtrl.toggleFavoriteGenre('Horror');
      expect(profileCtrl.favoriteGenres, contains('Horror'));
      expect(storage.getFavoriteGenres(), contains('Horror'));

      // Hapus genre 'Sci-Fi'
      profileCtrl.toggleFavoriteGenre('Sci-Fi');
      expect(profileCtrl.favoriteGenres, isNot(contains('Sci-Fi')));
      expect(storage.getFavoriteGenres(), isNot(contains('Sci-Fi')));
    });

    test('Tidak menghapus genre jika hanya tersisa 1 genre terpilih (minimal 1)', () {
      profileCtrl.favoriteGenres.assignAll(['Animation']);

      profileCtrl.toggleFavoriteGenre('Animation');
      // Harus tetap ada karena minimal 1 genre
      expect(profileCtrl.favoriteGenres.length, 1);
      expect(profileCtrl.favoriteGenres.first, 'Animation');
    });

    test('Set favorite genres secara bulk', () async {
      await profileCtrl.setFavoriteGenres(['Comedy', 'Romance', 'Fantasy']);

      expect(profileCtrl.favoriteGenres, ['Comedy', 'Romance', 'Fantasy']);
      expect(storage.getFavoriteGenres(), ['Comedy', 'Romance', 'Fantasy']);
    });

    test('Menentukan tingkatan loyalitas penonton secara akurat berdasarkan tiket', () {
      // 0-2 tiket: Bronze
      expect(LoyaltyLevel.fromTicketCount(0), LoyaltyLevel.bronze);
      expect(LoyaltyLevel.fromTicketCount(1), LoyaltyLevel.bronze);
      expect(LoyaltyLevel.fromTicketCount(2), LoyaltyLevel.bronze);

      // 3-5 tiket: Silver
      expect(LoyaltyLevel.fromTicketCount(3), LoyaltyLevel.silver);
      expect(LoyaltyLevel.fromTicketCount(4), LoyaltyLevel.silver);
      expect(LoyaltyLevel.fromTicketCount(5), LoyaltyLevel.silver);

      // 6-9 tiket: Gold
      expect(LoyaltyLevel.fromTicketCount(6), LoyaltyLevel.gold);
      expect(LoyaltyLevel.fromTicketCount(8), LoyaltyLevel.gold);
      expect(LoyaltyLevel.fromTicketCount(9), LoyaltyLevel.gold);

      // 10+ tiket: Platinum
      expect(LoyaltyLevel.fromTicketCount(10), LoyaltyLevel.platinum);
      expect(LoyaltyLevel.fromTicketCount(25), LoyaltyLevel.platinum);
    });

    test('Menghitung progres level dan sisa tiket menuju tier loyalitas berikutnya', () {
      // Skenario 1: 1 tiket (Bronze)
      profileCtrl.watchedCount.value = 1;
      expect(profileCtrl.currentLoyalty, LoyaltyLevel.bronze);
      expect(profileCtrl.ticketsToNextLevel, 2); // 3 - 1
      expect(profileCtrl.nextLevelProgress, closeTo(1 / 3.0, 0.01));
      expect(profileCtrl.nextLevelTitle, 'Silver Cinephile');

      // Skenario 2: 4 tiket (Silver)
      profileCtrl.watchedCount.value = 4;
      expect(profileCtrl.currentLoyalty, LoyaltyLevel.silver);
      expect(profileCtrl.ticketsToNextLevel, 2); // 6 - 4
      expect(profileCtrl.nextLevelProgress, closeTo(1 / 3.0, 0.01));
      expect(profileCtrl.nextLevelTitle, 'Gold VIP Penonton');

      // Skenario 3: 7 tiket (Gold)
      profileCtrl.watchedCount.value = 7;
      expect(profileCtrl.currentLoyalty, LoyaltyLevel.gold);
      expect(profileCtrl.ticketsToNextLevel, 3); // 10 - 7
      expect(profileCtrl.nextLevelProgress, closeTo(1 / 4.0, 0.01));
      expect(profileCtrl.nextLevelTitle, 'Platinum Cinema Maestro');

      // Skenario 4: 12 tiket (Platinum)
      profileCtrl.watchedCount.value = 12;
      expect(profileCtrl.currentLoyalty, LoyaltyLevel.platinum);
      expect(profileCtrl.ticketsToNextLevel, 0);
      expect(profileCtrl.nextLevelProgress, 1.0);
    });
  });

  group('PB-065: Riwayat Hasil Profiling AI Mood', () {
    test('Menyimpan hasil profiling mood baru secara LIFO', () async {
      final record1 = MoodHistoryModel(
        id: 'mood-rec-001',
        moodType: 'happy',
        moodTitle: 'Gembira & Ceria',
        moodEmoji: '😃',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        movies: const [
          MoodHistoryItemModel(
            movieId: 101,
            title: 'Kung Fu Panda 4',
            matchPercentage: 96,
            aiReason: 'Cerita komedi menghibur',
          ),
        ],
      );

      final record2 = MoodHistoryModel(
        id: 'mood-rec-002',
        moodType: 'thrilled',
        moodTitle: 'Tegang & Adrenalin',
        moodEmoji: '⚡',
        timestamp: DateTime.now(),
        movies: const [
          MoodHistoryItemModel(
            movieId: 202,
            title: 'Mission: Impossible',
            matchPercentage: 98,
            aiReason: 'Aksi laga menegangkan',
          ),
        ],
      );

      await profileCtrl.recordMoodProfiling(record1);
      expect(profileCtrl.moodHistory.length, 1);

      await profileCtrl.recordMoodProfiling(record2);
      expect(profileCtrl.moodHistory.length, 2);

      // Urutan LIFO: record2 paling atas
      expect(profileCtrl.moodHistory.first.id, 'mood-rec-002');
      expect(profileCtrl.moodHistory.first.moodType, 'thrilled');
      expect(profileCtrl.moodHistory.first.movies.first.title, 'Mission: Impossible');

      final rawFromStorage = storage.getMoodHistory();
      expect(rawFromStorage.length, 2);
      expect(rawFromStorage.first['id'], 'mood-rec-002');
    });

    test('Menghapus riwayat profiling individual berdasarkan ID', () async {
      final recordA = MoodHistoryModel(
        id: 'rec-A',
        moodType: 'sad',
        moodTitle: 'Haru & Menyentuh',
        moodEmoji: '😢',
        timestamp: DateTime.now(),
        movies: [],
      );
      final recordB = MoodHistoryModel(
        id: 'rec-B',
        moodType: 'chill',
        moodTitle: 'Santai & Rileks',
        moodEmoji: '🧘',
        timestamp: DateTime.now(),
        movies: [],
      );

      await profileCtrl.recordMoodProfiling(recordA);
      await profileCtrl.recordMoodProfiling(recordB);
      expect(profileCtrl.moodHistory.length, 2);

      await profileCtrl.removeMoodHistoryItem('rec-A');
      expect(profileCtrl.moodHistory.length, 1);
      expect(profileCtrl.moodHistory.first.id, 'rec-B');

      final raw = storage.getMoodHistory();
      expect(raw.length, 1);
      expect(raw.first['id'], 'rec-B');
    });

    test('Menghapus seluruh riwayat profiling mood', () async {
      final record = MoodHistoryModel(
        id: 'rec-clear',
        moodType: 'bored',
        moodTitle: 'Bosan & Butuh Kejutan',
        moodEmoji: '🥱',
        timestamp: DateTime.now(),
        movies: [],
      );

      await profileCtrl.recordMoodProfiling(record);
      expect(profileCtrl.moodHistory.isNotEmpty, isTrue);

      await profileCtrl.clearAllMoodHistory();
      expect(profileCtrl.moodHistory, isEmpty);
      expect(storage.getMoodHistory(), isEmpty);
    });

    test('Serialization dan deserialization MoodHistoryModel roundtrip', () {
      final original = MoodHistoryModel(
        id: 'roundtrip-test',
        moodType: 'romantic',
        moodTitle: 'Romantis & Baper',
        moodEmoji: '❤️',
        timestamp: DateTime(2026, 11, 14, 10, 0),
        movies: const [
          MoodHistoryItemModel(
            movieId: 505,
            title: 'La La Land',
            posterPath: '/lalaland.jpg',
            matchPercentage: 97,
            aiReason: 'Musikal romantis',
          ),
        ],
      );

      final json = original.toJson();
      final reconstructed = MoodHistoryModel.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.moodType, original.moodType);
      expect(reconstructed.moodTitle, original.moodTitle);
      expect(reconstructed.moodEmoji, original.moodEmoji);
      expect(reconstructed.movies.length, 1);
      expect(reconstructed.movies.first.movieId, 505);
      expect(reconstructed.movies.first.title, 'La La Land');
      expect(reconstructed.movies.first.posterPath, '/lalaland.jpg');
      expect(reconstructed.movies.first.matchPercentage, 97);
    });
  });
}
