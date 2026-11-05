// lib/utils/constants.dart
// Konstanta aplikasi global

class AppConstants {
  AppConstants._();

  // ── App Info ─────────────────────────────────────────────────────────────
  static const String appName = 'Cinemate';
  static const String appVersion = '1.0.0';

  // ── Env keys & Supabase Config ───────────────────────────────────────────
  static const String envSupabaseUrl = 'SUPABASE_URL';
  static const String envSupabaseAnonKey = 'SUPABASE_ANON_KEY';
  static const String envTmdbApiKey = 'TMDB_API_KEY';

  static const String defaultSupabaseUrl =
      'https://hbdhwsofkjkurewqnixk.supabase.co';
  static const String defaultSupabaseAnonKey =
      'sb_publishable_ps6_m_mcmw-Qe3fCokDJ2w_hUumridC';

  // ── Secure Storage Keys ───────────────────────────────────────────────────
  static const String keySessionToken = 'session_token';
  static const String keySessionUserId = 'session_user_id';
  static const String keySessionExpiry = 'session_expiry';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';

  // ── GetStorage Keys ───────────────────────────────────────────────────────
  static const String keyLoginAttempts = 'login_attempts';
  static const String keyLockoutUntil = 'lockout_until';
  static const String keyThemeMode = 'theme_mode';

  // ── Hive Box Names ────────────────────────────────────────────────────────
  static const String hiveBoxUser = 'user_cache';
  static const String hiveBoxMovies = 'movies_cache';
  static const String hiveBoxGeneral = 'general_cache';
  static const String boxMovies = 'movies_cache';
  static const String boxCinemas = 'cinemas_cache';
  static const String boxTickets = 'tickets_cache';
  static const String boxUserPrefs = 'user_prefs';
  static const String boxChatHistory = 'chat_history';

  // ── Auth Rules ────────────────────────────────────────────────────
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 5;
  static const int sessionExpiryDays = 7;

  static const int loginMaxAttempts = 5;
  static const int loginLockoutMinutes = 5;
  static const int sessionDurationDays = 7;

  // ── HTTP ──────────────────────────────────────────────────────────────────
  static const int httpConnectTimeoutMs = 15000;
  static const int httpReceiveTimeoutMs = 15000;
  static const int httpSendTimeoutMs = 15000;
  static const int httpMaxRetries = 2;

  static const int httpTimeoutSeconds = 15;
  static const int llmTimeoutSeconds = 30;

  // ── Validation ────────────────────────────────────────────────────────────
  static const int passwordMinLength = 8;
  static const int nameMinLength = 2;
}
