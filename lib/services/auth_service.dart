// lib/services/auth_service.dart
// Custom auth di atas tabel public.users Supabase (bukan Supabase Auth bawaan)
// Referensi: PB-005, PB-006, PB-007, PB-008, R-06
//
// Strategi hashing password (karena tidak ada bcrypt):
//   salt  = random UUID
//   hash  = SHA-256(password + salt)
//   stored = "$salt:$hash"
//
// Strategi session token:
//   raw_token = UUID → disimpan di secure_storage
//   token_hash = SHA-256(raw_token) → disimpan di tabel sessions

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';
import 'storage_service.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final _supabase = SupabaseService();
  final _storage = StorageService();
  final _uuid = const Uuid();

  SupabaseClient get _db => _supabase.client;

  // ================================================================
  // Hashing helpers
  // ================================================================

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  String _hashPassword(String password, String salt) =>
      _sha256(password + salt);

  bool _verifyPassword(String input, String storedHash) {
    // storedHash format: "salt:hash"
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expected = parts[1];
    return _sha256(input + salt) == expected;
  }

  String _hashToken(String rawToken) => _sha256(rawToken);

  // ================================================================
  // REGISTER (PB-005)
  // ================================================================

  /// Mendaftarkan pengguna baru.
  /// Melempar Exception jika email sudah terdaftar atau input tidak valid.
  Future<UserModel> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    // Cek duplikat email
    final existing = await _db
        .from('users')
        .select('id')
        .eq('email', email.toLowerCase().trim())
        .maybeSingle();

    if (existing != null) {
      throw Exception('Email sudah terdaftar. Silakan gunakan email lain.');
    }

    // Hash password
    final salt = _uuid.v4();
    final passwordHash = '$salt:${_hashPassword(password, salt)}';

    // Insert user
    final row = await _db
        .from('users')
        .insert({
          'email': email.toLowerCase().trim(),
          'password_hash': passwordHash,
          'full_name': fullName.trim(),
        })
        .select()
        .single();

    return UserModel.fromMap(row);
  }

  // ================================================================
  // LOGIN (PB-006)
  // ================================================================

  /// Login dengan email & password.
  /// Melempar Exception jika kredensial salah.
  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) async {
    // Ambil user by email
    final row = await _db
        .from('users')
        .select()
        .eq('email', email.toLowerCase().trim())
        .maybeSingle();

    if (row == null) {
      throw Exception('Email atau password salah.');
    }

    // Verifikasi password
    final storedHash = row['password_hash'] as String;
    if (!_verifyPassword(password, storedHash)) {
      throw Exception('Email atau password salah.');
    }

    final user = UserModel.fromMap(row);

    // Buat session token
    final rawToken = _uuid.v4();
    final tokenHash = _hashToken(rawToken);
    final expiresAt = DateTime.now()
        .toUtc()
        .add(const Duration(days: AppConstants.sessionDurationDays));

    // Simpan session ke Supabase
    await _db.from('sessions').insert({
      'user_id': user.id,
      'token_hash': tokenHash,
      'expires_at': expiresAt.toIso8601String(),
    });

    // Simpan token & user info ke secure storage
    await _storage.saveSessionToken(rawToken);
    await _storage.saveUserId(user.id);
    await _storage.saveUserEmail(user.email);

    return (user: user, token: rawToken);
  }

  // ================================================================
  // CHECK SESSION (PB-007)
  // ================================================================

  /// Cek apakah ada sesi valid di storage dan server.
  /// Return UserModel jika valid, null jika tidak valid / kedaluwarsa.
  Future<UserModel?> checkSession() async {
    final rawToken = await _storage.getSessionToken();
    if (rawToken == null) return null;

    final tokenHash = _hashToken(rawToken);

    // Validasi ke tabel sessions
    final sessionRow = await _db
        .from('sessions')
        .select()
        .eq('token_hash', tokenHash)
        .maybeSingle();

    if (sessionRow == null) {
      await _storage.clearSession();
      return null;
    }

    final session = SessionModel.fromMap(sessionRow);

    // Cek kedaluwarsa
    if (!session.isValid) {
      await _deleteSession(tokenHash);
      await _storage.clearSession();
      return null;
    }

    // Ambil data user
    final userId = await _storage.getUserId();
    if (userId == null) {
      await _storage.clearSession();
      return null;
    }

    final userRow =
        await _db.from('users').select().eq('id', userId).maybeSingle();

    if (userRow == null) {
      await _storage.clearSession();
      return null;
    }

    return UserModel.fromMap(userRow);
  }

  // ================================================================
  // LOGOUT (PB-008)
  // ================================================================

  /// Logout: hapus session dari Supabase + hapus dari secure storage.
  Future<void> logout() async {
    final rawToken = await _storage.getSessionToken();
    if (rawToken != null) {
      final tokenHash = _hashToken(rawToken);
      await _deleteSession(tokenHash);
    }
    await _storage.clearSession();
  }

  Future<void> _deleteSession(String tokenHash) async {
    await _db.from('sessions').delete().eq('token_hash', tokenHash);
  }
}
