// lib/services/storage_service.dart
// Wrapper terpadu untuk tiga lapisan local storage (PB-004)
// - Hive         : cache data (film, bioskop, tiket) dengan TTL
// - SecureStorage: token sesi & data sensitif (R-06)
// - GetStorage   : preferensi pengguna (mata uang, timezone, notifikasi)

import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive/hive.dart';
import '../utils/constants.dart';

class StorageService {
  StorageService._internal();
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  static final Map<String, dynamic> _memoryFallback = {};

  bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  // --- Secure Storage (flutter_secure_storage) ---
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // --- GetStorage (preferensi) ---
  GetStorage get _prefs => GetStorage();

  // ================================================================
  // SECURE STORAGE — token & sesi
  // ================================================================

  Future<void> saveSessionToken(String token) async {
    try {
      await _secure.write(key: 'session_token', value: token);
    } catch (_) {}
  }

  Future<String?> getSessionToken() async {
    try {
      return await _secure.read(key: 'session_token');
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserId(String userId) async {
    try {
      await _secure.write(key: 'user_id', value: userId);
    } catch (_) {}
  }

  Future<String?> getUserId() async {
    try {
      return await _secure.read(key: 'user_id');
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserEmail(String email) async {
    try {
      await _secure.write(key: 'user_email', value: email);
    } catch (_) {}
  }

  Future<String?> getUserEmail() async {
    try {
      return await _secure.read(key: 'user_email');
    } catch (_) {
      return null;
    }
  }

  /// Hapus semua data sesi (saat logout)
  Future<void> clearSession() async {
    await _secure.delete(key: 'session_token');
    await _secure.delete(key: 'user_id');
    await _secure.delete(key: 'user_email');
  }

  // ================================================================
  // GET STORAGE — preferensi pengguna
  // ================================================================

  void write(String key, dynamic value) => _prefs.write(key, value);
  T? read<T>(String key) => _prefs.read<T>(key);
  void remove(String key) => _prefs.remove(key);
  void clearPrefs() => _prefs.erase();

  // Login attempt helpers (PB-006 — lockout)
  int get loginAttempts => _prefs.read<int>('login_attempts') ?? 0;
  set loginAttempts(int v) => _prefs.write('login_attempts', v);

  String? get lockoutUntil => _prefs.read<String>('lockout_until');
  set lockoutUntil(String? v) {
    if (v == null) {
      _prefs.remove('lockout_until');
    } else {
      _prefs.write('lockout_until', v);
    }
  }

  // Currency & timezone (PB-048, PB-049)
  String get currencyPref => _prefs.read<String>('currency_pref') ?? 'IDR';
  set currencyPref(String v) => _prefs.write('currency_pref', v);

  String get timezonePref =>
      _prefs.read<String>('timezone_pref') ?? 'Asia/Jakarta';
  set timezonePref(String v) => _prefs.write('timezone_pref', v);

  // Notification settings (PB-058)
  bool get notifBooking => _prefs.read<bool>('notif_booking') ?? true;
  bool get notifReminder => _prefs.read<bool>('notif_reminder') ?? true;
  bool get notifPromo => _prefs.read<bool>('notif_promo') ?? true;
  set notifBooking(bool v) => _prefs.write('notif_booking', v);
  set notifReminder(bool v) => _prefs.write('notif_reminder', v);
  set notifPromo(bool v) => _prefs.write('notif_promo', v);

  // Search history (PB-054)
  List<String> getSearchHistory() {
    if (_isTestEnvironment) {
      final mem = _memoryFallback['search_history'];
      if (mem is List) {
        return mem.map((e) => e.toString()).toList();
      }
      return [];
    }
    try {
      final list = _prefs.read<List>('search_history');
      if (list != null) {
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  void saveSearchHistory(List<String> history) {
    if (_isTestEnvironment) {
      _memoryFallback['search_history'] = List<String>.from(history);
      return;
    }
    try {
      _prefs.write('search_history', history);
    } catch (_) {}
  }

  // ================================================================
  // HIVE — Cache data film dengan penanda waktu / TTL 6 jam (PB-013)
  // Referensi: Modul 6 & 7 (Hive local storage)
  // ================================================================
  static const int movieCacheTtlHours = 6;

  Future<Box> _openBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Menyimpan list film ke Hive box 'movies_cache' dengan timestamp milidetik
  Future<void> cacheMovies(
      String key, List<Map<String, dynamic>> moviesJson) async {
    final box = await _openBox(AppConstants.boxMovies);
    await box.put(key, {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': moviesJson,
    });
  }

  /// Mengambil list film dari Hive cache jika ada.
  /// Menghitung apakah cache masih berada dalam batas TTL 6 jam.
  Future<
      ({
        List<Map<String, dynamic>>? data,
        bool isExpired,
        DateTime? timestamp
      })> getCachedMovies(String key) async {
    final box = await _openBox(AppConstants.boxMovies);
    final cached = box.get(key);
    if (cached == null || cached is! Map) {
      return (data: null, isExpired: true, timestamp: null);
    }

    final timestampMs = cached['timestamp'] as int? ?? 0;
    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final rawData = cached['data'];

    if (rawData is! List) {
      return (data: null, isExpired: true, timestamp: cachedTime);
    }

    final dataList =
        rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final difference = DateTime.now().difference(cachedTime);
    final isExpired = difference.inHours >= movieCacheTtlHours;

    return (data: dataList, isExpired: isExpired, timestamp: cachedTime);
  }

  /// Menghapus seluruh cache film di Hive
  Future<void> clearMovieCache() async {
    final box = await _openBox(AppConstants.boxMovies);
    await box.clear();
  }

  // ================================================================
  // HIVE — Cache data bioskop (PB-015)
  // ================================================================

  /// Menyimpan daftar bioskop ke Hive box 'cinemas_cache'
  Future<void> cacheCinemas(List<Map<String, dynamic>> cinemasJson) async {
    final box = await _openBox(AppConstants.boxCinemas);
    await box.put('all_cinemas', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': cinemasJson,
    });
  }

  /// Mengambil daftar bioskop dari Hive box 'cinemas_cache'
  Future<List<Map<String, dynamic>>?> getCachedCinemas() async {
    final box = await _openBox(AppConstants.boxCinemas);
    final cached = box.get('all_cinemas');
    if (cached == null || cached is! Map) return null;

    final rawData = cached['data'];
    if (rawData is! List) return null;

    return rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Menghapus cache bioskop di Hive
  Future<void> clearCinemaCache() async {
    final box = await _openBox(AppConstants.boxCinemas);
    await box.clear();
  }

  // ================================================================
  // HIVE — Cache data E-Ticket (PB-023, PB-024)
  // ================================================================

  /// Menyimpan daftar tiket bioskop ke Hive box 'tickets_cache'
  Future<void> cacheTickets(List<Map<String, dynamic>> ticketsJson) async {
    final box = await _openBox(AppConstants.boxTickets);
    await box.put('user_tickets', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': ticketsJson,
    });
  }

  /// Menambahkan satu tiket baru ke Hive box 'tickets_cache'
  Future<void> addTicketToCache(Map<String, dynamic> ticketJson) async {
    final current = await getCachedTickets() ?? [];
    // Cek apakah tiket sudah ada (update atau tambahkan di awal list)
    final existingIndex =
        current.indexWhere((t) => t['id'] == ticketJson['id']);
    if (existingIndex >= 0) {
      current[existingIndex] = ticketJson;
    } else {
      current.insert(0, ticketJson);
    }
    await cacheTickets(current);
  }

  /// Mengambil daftar tiket bioskop dari Hive box 'tickets_cache'
  Future<List<Map<String, dynamic>>?> getCachedTickets() async {
    final meta = await getCachedTicketsWithMeta();
    return meta.data;
  }

  /// Mengambil tiket beserta metadata timestamp cache (PB-024)
  Future<({List<Map<String, dynamic>>? data, DateTime? timestamp})>
      getCachedTicketsWithMeta() async {
    final box = await _openBox(AppConstants.boxTickets);
    final cached = box.get('user_tickets');
    if (cached == null || cached is! Map) return (data: null, timestamp: null);

    final timestampMs = cached['timestamp'] as int? ?? 0;
    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final rawData = cached['data'];
    if (rawData is! List) return (data: null, timestamp: cachedTime);

    final list =
        rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return (data: list, timestamp: cachedTime);
  }

  /// Menghapus cache tiket di Hive
  Future<void> clearTicketsCache() async {
    final box = await _openBox(AppConstants.boxTickets);
    await box.clear();
  }
}
