// lib/controllers/profile_controller.dart
// Controller untuk modul Profil Lanjutan, My Cinemate, Pengaturan & Riwayat AI (PB-061, PB-063, PB-064, PB-065)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/mood_history_model.dart';
import '../services/fnb_service.dart';
import '../services/storage_service.dart';
import '../services/ticket_service.dart';
import 'auth_controller.dart';

enum LoyaltyLevel {
  bronze('Bronze Moviegoer', '🥉', 0, 2, Color(0xFFCD7F32)),
  silver('Silver Cinephile', '🥈', 3, 5, Color(0xFFC0C0C0)),
  gold('Gold VIP Penonton', '🥇', 6, 9, Color(0xFFFFD700)),
  platinum('Platinum Cinema Maestro', '👑', 10, 9999, Color(0xFFE5E4E2));

  final String title;
  final String icon;
  final int minTickets;
  final int maxTickets;
  final Color color;

  const LoyaltyLevel(
    this.title,
    this.icon,
    this.minTickets,
    this.maxTickets,
    this.color,
  );

  static LoyaltyLevel fromTicketCount(int count) {
    if (count >= 10) return LoyaltyLevel.platinum;
    if (count >= 6) return LoyaltyLevel.gold;
    if (count >= 3) return LoyaltyLevel.silver;
    return LoyaltyLevel.bronze;
  }
}

class ProfileController extends GetxController {
  final StorageService _storage;
  final TicketService _ticketService;
  final FnbService _fnbService;
  final ImagePicker _imagePicker;

  ProfileController({
    StorageService? storage,
    TicketService? ticketService,
    FnbService? fnbService,
    ImagePicker? imagePicker,
  })  : _storage = storage ?? StorageService(),
        _ticketService = ticketService ?? TicketService(),
        _fnbService = fnbService ?? FnbService(),
        _imagePicker = imagePicker ?? ImagePicker();

  // =========================================================================
  // 1. PB-061: UNGGAH FOTO PROFIL (KAMERA / GALERI / PRESET FALLBACK)
  // =========================================================================

  /// Path file foto avatar lokal di perangkat
  final avatarPath = RxnString();

  /// Mengambil foto profil baru dari kamera atau galeri
  Future<bool> pickProfileImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null) return false;

      final path = pickedFile.path;
      avatarPath.value = path;
      _storage.avatarPath = path;

      // Update di AuthController jika terdaftar
      if (Get.isRegistered<AuthController>()) {
        final authCtrl = Get.find<AuthController>();
        final current = authCtrl.currentUser.value;
        if (current != null) {
          authCtrl.currentUser.value = current.copyWith(avatarUrl: path);
        }
      }

      return true;
    } catch (e) {
      debugPrint('[ProfileController] Gagal memilih foto: $e');
      return false;
    }
  }

  /// Menghapus foto profil kustom dan kembali ke avatar bawaan
  Future<void> removeCustomAvatar() async {
    avatarPath.value = null;
    _storage.avatarPath = null;
    if (Get.isRegistered<AuthController>()) {
      final authCtrl = Get.find<AuthController>();
      final current = authCtrl.currentUser.value;
      if (current != null) {
        authCtrl.currentUser.value = current.copyWith(avatarUrl: null);
      }
    }
  }

  // =========================================================================
  // 2. PB-063: HALAMAN PENGATURAN APLIKASI LANJUTAN
  // =========================================================================

  /// Preferensi tema aplikasi: 'dark', 'light', 'system'
  final themeMode = 'dark'.obs;

  /// Preferensi login biometrik (Fingerprint / Face ID)
  final isBiometricEnabled = false.obs;

  void setThemeMode(String mode) {
    themeMode.value = mode;
    _storage.themeMode = mode;
    if (mode == 'light') {
      Get.changeThemeMode(ThemeMode.light);
    } else if (mode == 'dark') {
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      Get.changeThemeMode(ThemeMode.system);
    }
  }

  void setBiometricEnabled(bool enabled) {
    isBiometricEnabled.value = enabled;
    _storage.biometricEnabled = enabled;
  }

  /// Membersihkan seluruh cache offline aplikasi di Hive
  Future<void> clearAppCache() async {
    await _storage.clearMovieCache();
    await _storage.clearCinemaCache();
    await _storage.clearTicketsCache();
  }

  /// Mengatur ulang preferensi ke default
  Future<void> resetAllPreferences() async {
    _storage.currencyPref = 'IDR';
    _storage.timezonePref = 'Asia/Jakarta';
    _storage.notifBooking = true;
    _storage.notifReminder = true;
    _storage.notifFnb = true;
    _storage.notifPromo = true;
    setThemeMode('dark');
    setBiometricEnabled(false);
  }

  // =========================================================================
  // 3. PB-064: LAYAR "MY CINEMATE" (STATISTIK, GENRE & BADGE LOYALITAS)
  // =========================================================================

  static const List<String> allAvailableGenres = [
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Fantasy',
    'Horror',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Thriller',
  ];

  /// Preferensi genre favorit yang dipilih penonton
  final favoriteGenres = <String>[].obs;

  /// Statistik Penonton
  final watchedCount = 0.obs;
  final totalWatchMinutes = 0.obs;
  final totalSpentIdr = 0.obs;
  final isLoadingStats = false.obs;

  /// Tingkat loyalitas penonton saat ini
  LoyaltyLevel get currentLoyalty =>
      LoyaltyLevel.fromTicketCount(watchedCount.value);

  /// Progress (0.0 s.d. 1.0) menuju level loyalitas berikutnya
  double get nextLevelProgress {
    final count = watchedCount.value;
    if (count >= 10) return 1.0;
    if (count >= 6) return (count - 6) / (10 - 6);
    if (count >= 3) return (count - 3) / (6 - 3);
    return count / 3.0;
  }

  /// Sisa jumlah tiket untuk naik level loyalitas
  int get ticketsToNextLevel {
    final count = watchedCount.value;
    if (count >= 10) return 0;
    if (count >= 6) return 10 - count;
    if (count >= 3) return 6 - count;
    return 3 - count;
  }

  /// Label tier berikutnya
  String get nextLevelTitle {
    final count = watchedCount.value;
    if (count >= 10) return 'Maksimal (Platinum)';
    if (count >= 6) return 'Platinum Cinema Maestro';
    if (count >= 3) return 'Gold VIP Penonton';
    return 'Silver Cinephile';
  }

  /// Toggle seleksi genre favorit penonton
  void toggleFavoriteGenre(String genre) {
    if (favoriteGenres.contains(genre)) {
      if (favoriteGenres.length > 1) {
        favoriteGenres.remove(genre);
      }
    } else {
      favoriteGenres.add(genre);
    }
    _storage.saveFavoriteGenres(favoriteGenres.toList());
  }

  /// Menyimpan daftar genre favorit sekaligus
  Future<void> setFavoriteGenres(List<String> genres) async {
    favoriteGenres.assignAll(genres);
    await _storage.saveFavoriteGenres(genres);
  }

  /// Memuat statistik film yang sudah ditonton penonton
  Future<void> loadProfileStats() async {
    isLoadingStats.value = true;
    try {
      final tickets = await _ticketService.getUserTickets();
      final fnbOrders = await _fnbService.getUserOrders();

      watchedCount.value = tickets.length;
      totalWatchMinutes.value = tickets.length * 120; // Est. 120 menit/film

      int spend = 0;
      for (final t in tickets) {
        spend += t.totalPrice;
      }
      for (final f in fnbOrders) {
        spend += f.totalPrice;
      }
      totalSpentIdr.value = spend;
    } catch (e) {
      debugPrint('[ProfileController] Gagal memuat statistik: $e');
    } finally {
      isLoadingStats.value = false;
    }
  }

  // =========================================================================
  // 4. PB-065: RIWAYAT HASIL PROFILING AI MOOD
  // =========================================================================

  /// Daftar riwayat profiling AI Mood yang tersimpan
  final moodHistory = <MoodHistoryModel>[].obs;

  /// Memuat riwayat dari local storage
  void loadMoodHistory() {
    final raw = _storage.getMoodHistory();
    final items = raw.map((json) => MoodHistoryModel.fromJson(json)).toList();
    moodHistory.assignAll(items);
  }

  /// Menambahkan riwayat profiling baru (LIFO)
  Future<void> recordMoodProfiling(MoodHistoryModel record) async {
    await _storage.addMoodHistory(record.toJson());
    moodHistory.insert(0, record);
    if (moodHistory.length > 20) {
      moodHistory.removeLast();
    }
  }

  /// Menghapus satu entri riwayat berdasarkan ID
  Future<void> removeMoodHistoryItem(String id) async {
    await _storage.deleteMoodHistory(id);
    moodHistory.removeWhere((item) => item.id == id);
  }

  /// Menghapus seluruh riwayat profiling AI
  Future<void> clearAllMoodHistory() async {
    await _storage.clearMoodHistory();
    moodHistory.clear();
  }

  @override
  void onInit() {
    super.onInit();
    // Inisialisasi state dari local storage
    avatarPath.value = _storage.avatarPath;
    themeMode.value = _storage.themeMode;
    isBiometricEnabled.value = _storage.biometricEnabled;
    favoriteGenres.assignAll(_storage.getFavoriteGenres());

    loadMoodHistory();
    loadProfileStats();
  }
}
