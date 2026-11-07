// lib/bindings/booking_binding.dart
// Binding untuk alur pemesanan tiket bioskop (PB-018)

import 'package:get/get.dart';
import '../controllers/booking_cinema_controller.dart';

class BookByCinemaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookByCinemaController>(() => BookByCinemaController());
  }
}
