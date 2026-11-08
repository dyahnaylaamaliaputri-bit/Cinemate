// lib/services/http_service.dart
// Lapisan HTTP terpusat menggunakan Dio (PB-003)
// - Singleton Dio instance
// - Interceptor: inject token + logging
// - Timeout: 15 detik (LLM: 30 detik)
// - Retry: maksimal 2 kali
// - Error terstandar
// Referensi: NFR-003, NFR-005, NFR-016, NFR-033

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'storage_service.dart';

class HttpService {
  HttpService._internal();
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;

  late final Dio _dio;
  final _storage = StorageService();

  static const int _defaultTimeout = 15;
  static const int _llmTimeout = 30;
  static const int _maxRetries = 2;

  void initialize() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: _defaultTimeout),
      receiveTimeout: const Duration(seconds: _defaultTimeout),
      sendTimeout: const Duration(seconds: _defaultTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(_RetryInterceptor(_dio, _maxRetries));
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (o) => debugPrint('[HTTP] $o'),
    ));
  }

  /// GET request
  Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(url, queryParameters: queryParameters, options: options);

  /// POST request
  Future<Response<T>> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool isLlm = false,
  }) {
    final opts = (options ?? Options()).copyWith(
      receiveTimeout: isLlm
          ? const Duration(seconds: _llmTimeout)
          : const Duration(seconds: _defaultTimeout),
    );
    return _dio.post<T>(url,
        data: data, queryParameters: queryParameters, options: opts);
  }

  /// Membangun URL gambar TMDB
  static String tmdbImageUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/$size$path';
  }
}

// ── Interceptor: inject Authorization header ────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final StorageService _storage;
  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Inject token untuk TMDB API
    final tmdbKey = dotenv.env['TMDB_API_KEY'];
    if (options.baseUrl.contains('themoviedb') && tmdbKey != null) {
      options.headers['Authorization'] = 'Bearer $tmdbKey';
    } else {
      final token = await _storage.getSessionToken();
      if (token != null && !options.headers.containsKey('Authorization')) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(_normalizeError(err));
  }

  DioException _normalizeError(DioException err) {
    String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        message = 'Koneksi timeout. Periksa koneksi internet Anda.';
        break;
      case DioExceptionType.connectionError:
        message = 'Tidak dapat terhubung ke server.';
        break;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        message = 'Error server ($code). Silakan coba lagi.';
        break;
      default:
        message = 'Terjadi kesalahan. Silakan coba lagi.';
    }
    return DioException(
      requestOptions: err.requestOptions,
      error: message,
      type: err.type,
      response: err.response,
    );
  }
}

// ── Interceptor: retry otomatis ─────────────────────────────────────────────
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;
  _RetryInterceptor(this._dio, this._maxRetries);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = (extra['retry_count'] as int?) ?? 0;

    final shouldRetry = retryCount < _maxRetries &&
        err.type != DioExceptionType.badResponse &&
        err.type != DioExceptionType.cancel;

    if (shouldRetry) {
      err.requestOptions.extra['retry_count'] = retryCount + 1;
      await Future<void>.delayed(Duration(seconds: retryCount + 1));
      try {
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // akan di-handle oleh interceptor berikutnya
      }
    }
    handler.next(err);
  }
}

// ignore_for_file: avoid_print
void debugPrint(String msg) => print(msg);
