// lib/controllers/order_summary_controller.dart
// Controller Ringkasan Pesanan (PB-020)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/booking_order_model.dart';
import '../models/cinema_model.dart';
import '../models/movie_model.dart';
import '../models/showtime_model.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import 'auth_controller.dart';

class OrderSummaryController extends GetxController {
  final StorageService _storage = StorageService();

  late final Rx<BookingOrderModel> order;

  /// Informasi pengguna pemesan
  final userName = 'Pengguna Cinemate'.obs;
  final userEmail = 'user@cinemate.id'.obs;

  /// Timer hitung mundur reservasi pesanan (10 menit)
  final remainingSeconds = 600.obs;
  Timer? _timer;

  /// Kode voucher diskon promo
  final voucherCodeController = TextEditingController();
  final discountAmount = 0.obs;
  final isVoucherApplied = false.obs;
  final voucherError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initOrder();
    _loadUserInfo();
    _startReservationTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    voucherCodeController.dispose();
    super.onClose();
  }

  void _initOrder() {
    final args = Get.arguments;
    if (args is BookingOrderModel) {
      order = Rx<BookingOrderModel>(args);
    } else {
      // Fallback draft pesanan jika dibuka tanpa arguments
      order = Rx<BookingOrderModel>(
        BookingOrderModel(
          id: 'ORD-DEMO',
          movie: MovieModel(
            id: 1,
            title: 'Inside Out 2',
            overview: 'Riley kini beranjak remaja.',
            voteAverage: 8.0,
            voteCount: 5200,
            genreIds: [16, 10751, 35],
            popularity: 200.0,
          ),
          cinema: CinemaModel(
            id: 'cin-1',
            name: 'Metro Cinema Senayan',
            address: 'Jl. Asia Afrika No. 8, Jakarta Selatan',
            latitude: -6.2176,
            longitude: 106.8013,
          ),
          showtime: ShowtimeModel(
            id: 'st-demo',
            cinemaId: 'cin-1',
            movieId: 1,
            movieTitle: 'Inside Out 2',
            showDate: '2026-11-07',
            showTime: '14:00',
            hallName: 'Studio 1',
            experience: 'Regular 2D',
            price: 50000,
            totalSeats: 56,
            availableSeats: 48,
          ),
          selectedSeats: ['C4', 'C5'],
          ticketPrice: 50000,
          serviceFeePerTicket: 3000,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _loadUserInfo() async {
    if (Get.isRegistered<AuthController>()) {
      final user = Get.find<AuthController>().currentUser.value;
      if (user != null) {
        if (user.fullName.isNotEmpty) userName.value = user.fullName;
        if (user.email.isNotEmpty) userEmail.value = user.email;
        return;
      }
    }
    final email = await _storage.getUserEmail();
    if (email != null && email.isNotEmpty) {
      userEmail.value = email;
      final localName = email.split('@').first;
      userName.value = localName.capitalizeFirst ?? localName;
    }
  }

  void _startReservationTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        timer.cancel();
      }
    });
  }

  /// String format timer MM:SS
  String get formattedTimer {
    final m = (remainingSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Terapkan kode voucher promo
  void applyVoucher() {
    voucherError.value = '';
    final code = voucherCodeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      voucherError.value = 'Silakan masukkan kode promo';
      return;
    }

    if (code == 'CINEMATEHEMAT' || code == 'DISKON10') {
      discountAmount.value = 10000;
      isVoucherApplied.value = true;
      Get.snackbar(
        'Promo Diterapkan!',
        'Potongan sebesar Rp 10.000 berhasil digunakan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF16213E),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50)),
      );
    } else {
      voucherError.value = 'Kode voucher tidak valid';
      discountAmount.value = 0;
      isVoucherApplied.value = false;
    }
  }

  /// Batalkan voucher
  void removeVoucher() {
    voucherCodeController.clear();
    discountAmount.value = 0;
    isVoucherApplied.value = false;
    voucherError.value = '';
  }

  /// Total akhir setelah diskon
  int get finalTotalAmount {
    final total = order.value.totalAmount - discountAmount.value;
    return total > 0 ? total : 0;
  }

  String get formattedFinalTotalAmount => BookingOrderModel.formatRupiah(finalTotalAmount);
  String get formattedDiscount => BookingOrderModel.formatRupiah(discountAmount.value);

  /// Aksi lanjut ke pembayaran (PB-021)
  void proceedToPayment() {
    final updatedOrder = order.value.copyWith(discountAmount: discountAmount.value);
    order.value = updatedOrder;
    Get.toNamed(Routes.payment, arguments: updatedOrder);
  }
}
