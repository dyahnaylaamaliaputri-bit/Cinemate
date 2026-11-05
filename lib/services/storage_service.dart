// lib/services/storage_service.dart
// Wrapper terpadu untuk tiga lapisan local storage (PB-004)
// - Hive         : cache data (film, bioskop, tiket) dengan TTL
// - SecureStorage: token sesi & data sensitif (R-06)
// - GetStorage   : preferensi pengguna (mata uang, timezone, notifikasi)

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';

class StorageService {
  StorageService._internal();
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  // --- Secure Storage (flutter_secure_storage) ---
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // --- GetStorage (preferensi) ---
  final _prefs = GetStorage();

  // ================================================================
  // SECURE STORAGE — token & sesi
  // ================================================================

  Future<void> saveSessionToken(String token) =>
      _secure.write(key: 'session_token', value: token);

  Future<String?> getSessionToken() =>
      _secure.read(key: 'session_token');

  Future<void> saveUserId(String userId) =>
      _secure.write(key: 'user_id', value: userId);

  Future<String?> getUserId() =>
      _secure.read(key: 'user_id');

  Future<void> saveUserEmail(String email) =>
      _secure.write(key: 'user_email', value: email);

  Future<String?> getUserEmail() =>
      _secure.read(key: 'user_email');

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
  bool get notifBooking  => _prefs.read<bool>('notif_booking')  ?? true;
  bool get notifReminder => _prefs.read<bool>('notif_reminder') ?? true;
  bool get notifPromo    => _prefs.read<bool>('notif_promo')    ?? true;
  set notifBooking(bool v)  => _prefs.write('notif_booking',  v);
  set notifReminder(bool v) => _prefs.write('notif_reminder', v);
  set notifPromo(bool v)    => _prefs.write('notif_promo',    v);
}
