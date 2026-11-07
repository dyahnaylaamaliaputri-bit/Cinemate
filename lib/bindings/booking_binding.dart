// lib/bindings/booking_binding.dart
// Binding untuk alur pemesanan tiket bioskop (PB-018, PB-019, PB-020)

import 'package:get/get.dart';
import '../controllers/booking_cinema_controller.dart';
import '../controllers/booking_movie_controller.dart';
import '../controllers/booking_seat_controller.dart';
import '../controllers/order_summary_controller.dart';

class BookByCinemaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookByCinemaController>(() => BookByCinemaController());
  }
}

class BookByMovieBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookByMovieController>(() => BookByMovieController());
  }
}

class BookingSeatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingSeatController>(() => BookingSeatController());
  }
}

class OrderSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderSummaryController>(() => OrderSummaryController());
  }
}
