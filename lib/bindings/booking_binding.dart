// lib/bindings/booking_binding.dart
// Binding untuk alur pemesanan tiket bioskop (PB-018, PB-019)

import 'package:get/get.dart';
import '../controllers/booking_cinema_controller.dart';
import '../controllers/booking_movie_controller.dart';

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
