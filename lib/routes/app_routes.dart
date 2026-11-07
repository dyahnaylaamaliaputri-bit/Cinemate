// lib/routes/app_routes.dart
// Nama-nama route GetX untuk navigasi
// Referensi: PB-001, SRS §5.1

abstract class Routes {
  Routes._();

  static const splash    = '/';
  static const login     = '/login';
  static const register  = '/register';
  static const dashboard = '/dashboard';
  static const profile   = '/profile';
  static const tickets   = '/tickets';
  static const fnb       = '/fnb';
  static const movieDetail = '/movie-detail';
  static const bookByCinema = '/book-by-cinema';
  static const bookByMovie  = '/book-by-movie';
  static const selectSeat   = '/select-seat';
  static const orderSummary = '/order-summary';
  static const payment      = '/payment';
}
