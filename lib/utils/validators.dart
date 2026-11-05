// lib/utils/validators.dart
// Validasi form: email, password, nama, phone

class Validators {
  Validators._();

  // ── Email ─────────────────────────────────────────────────────────────────
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Format email tidak valid';
    }
    return null;
  }
  static String? email(String? value) => validateEmail(value);

  // ── Password ──────────────────────────────────────────────────────────────
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Password harus mengandung huruf';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password harus mengandung angka';
    }
    return null;
  }
  static String? password(String? value) => validatePassword(value);

  // ── Konfirmasi Password ───────────────────────────────────────────────────
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }
  static String? confirmPassword(String? value, String password) =>
      validateConfirmPassword(value, password);

  // ── Nama Lengkap ──────────────────────────────────────────────────────────
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap tidak boleh kosong';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Nama minimal 2 karakter';
    }
    return null;
  }
  static String? fullName(String? value) => validateFullName(value);

  // ── Phone ─────────────────────────────────────────────────────────────────
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final phone = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone)) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }
  static String? phone(String? value) => validatePhone(value);

  // ── Required Field ────────────────────────────────────────────────────────
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }
  static String? required(String? value, {String fieldName = 'Field'}) =>
      validateRequired(value, fieldName: fieldName);
}
