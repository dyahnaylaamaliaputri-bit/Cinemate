// lib/controllers/auth_controller.dart
// GetxController untuk state autentikasi
// Referensi: PB-005, PB-006, PB-007, PB-008

import 'package:get/get.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AuthController extends GetxController {
  final AuthRepository _repository;
  final StorageService _storage;

  AuthController({
    AuthRepository? repository,
    StorageService? storage,
  })  : _repository = repository ?? AuthRepositoryImpl(),
        _storage = storage ?? StorageService();

  // ── Observable state ──────────────────────────────────────────────────────
  final isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final errorMessage = ''.obs;

  // Lockout state (PB-006)
  final loginAttempts = 0.obs;
  final Rx<DateTime?> lockoutUntil = Rx<DateTime?>(null);

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _restoreLockoutState();
  }

  void _restoreLockoutState() {
    loginAttempts.value = _storage.loginAttempts;
    final lockoutStr = _storage.lockoutUntil;
    if (lockoutStr != null) {
      lockoutUntil.value = DateTime.tryParse(lockoutStr);
    }
  }

  // ── Lockout helpers ───────────────────────────────────────────────────────

  bool get isLockedOut {
    final until = lockoutUntil.value;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    // Lockout sudah selesai — reset
    _resetLockout();
    return false;
  }

  Duration get remainingLockout {
    final until = lockoutUntil.value;
    if (until == null) return Duration.zero;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _incrementAttempts() {
    loginAttempts.value++;
    _storage.loginAttempts = loginAttempts.value;

    if (loginAttempts.value >= AppConstants.loginMaxAttempts) {
      final until = DateTime.now()
          .add(const Duration(minutes: AppConstants.loginLockoutMinutes));
      lockoutUntil.value = until;
      _storage.lockoutUntil = until.toIso8601String();
    }
  }

  void _resetLockout() {
    loginAttempts.value = 0;
    lockoutUntil.value = null;
    _storage.loginAttempts = 0;
    _storage.lockoutUntil = null;
  }

  // ── CHECK SESSION (PB-007) ────────────────────────────────────────────────

  Future<void> checkSession() async {
    isLoading.value = true;
    try {
      final user = await _repository.checkSession();
      if (user != null) {
        currentUser.value = user;
        Get.offAllNamed(Routes.dashboard);
      } else {
        Get.offAllNamed(Routes.login);
      }
    } catch (_) {
      Get.offAllNamed(Routes.login);
    } finally {
      isLoading.value = false;
    }
  }

  // ── REGISTER (PB-005) ─────────────────────────────────────────────────────

  Future<void> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _repository.register(
        email: email,
        fullName: fullName,
        password: password,
      );
      Get.snackbar(
        'Registrasi Berhasil',
        'Akun berhasil dibuat. Silakan login.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offNamed(Routes.login);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Registrasi Gagal',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── LOGIN (PB-006) ────────────────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (isLockedOut) {
      final mins = remainingLockout.inMinutes;
      final secs = remainingLockout.inSeconds % 60;
      Get.snackbar(
        'Akun Dikunci',
        'Terlalu banyak percobaan. Coba lagi dalam ${mins}m ${secs}s.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _repository.login(email: email, password: password);
      currentUser.value = result.user;
      _resetLockout();
      Get.offAllNamed(Routes.dashboard);
    } catch (e) {
      _incrementAttempts();
      errorMessage.value = 'Email atau password salah.';
      Get.snackbar(
        'Login Gagal',
        isLockedOut
            ? 'Terlalu banyak percobaan. Akun dikunci ${AppConstants.loginLockoutMinutes} menit.'
            : errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── LOGOUT (PB-008) ───────────────────────────────────────────────────────

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _repository.logout();
      currentUser.value = null;
      Get.offAllNamed(Routes.login);
    } catch (_) {
      // Tetap logout lokal meskipun server gagal
      currentUser.value = null;
      Get.offAllNamed(Routes.login);
    } finally {
      isLoading.value = false;
    }
  }
}
