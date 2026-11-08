// lib/controllers/payment_controller.dart
// Controller simulasi pembayaran tiket bioskop (PB-021)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/booking_order_model.dart';
import '../models/cinema_model.dart';
import '../models/movie_model.dart';
import '../models/payment_method_model.dart';
import '../models/showtime_model.dart';
import '../models/ticket_model.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../services/ticket_service.dart';
import 'tickets_controller.dart';

class PaymentController extends GetxController {
  late final Rx<BookingOrderModel> order;

  /// Daftar semua metode pembayaran
  final allMethods = PaymentMethodModel.predefinedMethods;

  /// Kategori metode pembayaran yang dipilih (Virtual Account / E-Wallet / QRIS)
  final selectedCategory = PaymentCategory.virtualAccount.obs;

  /// Metode pembayaran spesifik yang dipilih
  late final Rx<PaymentMethodModel> selectedMethod;

  /// Timer hitung mundur 10 menit (600 detik)
  final remainingSeconds = 600.obs;
  Timer? _countdownTimer;

  /// Status proses pembayaran
  final isProcessing = false.obs;
  final isPaymentSuccess = false.obs;
  final createdTicket = Rx<TicketModel?>(null);

  /// Input nomor ponsel untuk E-Wallet
  final phoneController = TextEditingController(text: '081234567890');

  @override
  void onInit() {
    super.onInit();
    _initOrder();
    selectedMethod = Rx<PaymentMethodModel>(allMethods.first);
    _startCountdownTimer();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    phoneController.dispose();
    super.onClose();
  }

  void _initOrder() {
    final args = Get.arguments;
    if (args is BookingOrderModel) {
      order = Rx<BookingOrderModel>(args);
    } else {
      order = Rx<BookingOrderModel>(
        BookingOrderModel(
          id: 'ORD-DEMO-021',
          movie: MovieModel(
            id: 533535,
            title: 'Deadpool & Wolverine',
            overview: 'Wade Wilson and Logan team up.',
            voteAverage: 7.9,
            voteCount: 1500,
            genreIds: [28, 35],
            popularity: 300.0,
          ),
          cinema: CinemaModel(
            id: 'cin-1',
            name: 'Metro Cinema Senayan',
            address: 'Jl. Asia Afrika No. 8, Jakarta Selatan',
            latitude: -6.2176,
            longitude: 106.8013,
          ),
          showtime: ShowtimeModel(
            id: 'st-101',
            cinemaId: 'cin-1',
            movieId: 533535,
            movieTitle: 'Deadpool & Wolverine',
            showDate: '2026-11-07',
            showTime: '14:00',
            hallName: 'Studio 1',
            experience: 'Regular 2D',
            price: 50000,
            totalSeats: 56,
            availableSeats: 48,
          ),
          selectedSeats: ['C2', 'C3'],
          ticketPrice: 50000,
          serviceFeePerTicket: 3000,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Memulai timer hitung mundur pembayaran 10 menit
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        timer.cancel();
        _handleOrderExpired();
      }
    });
  }

  /// Format MM:SS untuk countdown timer
  String get formattedTimer {
    final m = (remainingSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Penanganan saat batas waktu bayar habis
  void _handleOrderExpired() {
    order.value = order.value.copyWith(status: 'expired');
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.timer_off_rounded, color: Color(0xFFE53935)),
              SizedBox(width: 10),
              Text('Waktu Habis',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Batas waktu pembayaran 10 menit telah berakhir. Kursi pesanan Anda telah dilepaskan kembali.',
            style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Get.until((route) => route.settings.name == Routes.dashboard);
              },
              child: const Text('Kembali ke Dashboard',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Mengubah kategori metode pembayaran (VA / E-Wallet / QRIS)
  void selectCategory(PaymentCategory category) {
    selectedCategory.value = category;
    final matching = allMethods.where((m) => m.category == category).toList();
    if (matching.isNotEmpty) {
      selectedMethod.value = matching.first;
    }
  }

  /// Memilih metode pembayaran tertentu
  void selectMethod(PaymentMethodModel method) {
    selectedMethod.value = method;
  }

  /// Menyalin teks nomor VA ke clipboard
  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text.replaceAll(' ', '')));
    Get.snackbar(
      'Tersalin!',
      'Nomor Virtual Account telah disalin ke clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF16213E),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.copy_rounded, color: Color(0xFF4CAF50)),
    );
  }

  /// Simulasi Proses Pembayaran Menjadi "PAID" (PB-021)
  Future<void> payNow() async {
    if (isProcessing.value) return;

    isProcessing.value = true;

    // Simulasi jeda pemrosesan jaringan perbankan / gateway (1.5 detik)
    await Future.delayed(const Duration(milliseconds: 1500));

    final ref =
        'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final updated = order.value.copyWith(
      status: 'paid',
      paymentMethod: selectedMethod.value.name,
      paidAt: DateTime.now(),
      paymentReference: ref,
    );

    order.value = updated;

    // Simpan ke Supabase & Hive via TicketService (PB-022, PB-023)
    final userId = await StorageService().getUserId() ?? 'usr-local';
    final ticket =
        await TicketService().createBooking(order: updated, userId: userId);
    createdTicket.value = ticket;

    // Sinkronkan ke TicketsController jika terdaftar
    try {
      if (Get.isRegistered<TicketsController>()) {
        Get.find<TicketsController>().loadTickets(forceRefresh: true);
      }
    } catch (_) {}

    isProcessing.value = false;
    isPaymentSuccess.value = true;
    _countdownTimer?.cancel();

    _showPaymentSuccessDialog();
  }

  /// Menampilkan dialog / modal sukses pembayaran
  void _showPaymentSuccessDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Centang Hijau Beranimasi
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.check_rounded,
                    color: Color(0xFF4CAF50), size: 40),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Status pesanan Anda telah berubah menjadi PAID.',
              style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Card Ringkasan Pembayaran
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E2E4E)),
              ),
              child: Column(
                children: [
                  _buildReceiptRow(
                      'No. Referensi', order.value.paymentReference ?? '-'),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Film', order.value.movie.title),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Bioskop', order.value.cinema.name),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Kursi (${order.value.seatCount})',
                      order.value.seatsLabel),
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                      'Metode Bayar', order.value.paymentMethod ?? '-'),
                  const Divider(color: Color(0xFF2A2A3E), height: 16),
                  _buildReceiptRow(
                      'Total Dibayar', order.value.formattedTotalAmount,
                      isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF2E2E4E)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Get.until(
                          (route) => route.settings.name == Routes.dashboard);
                    },
                    child: const Text('Ke Beranda',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: const Text(
                      'Lihat E-Ticket (PB-022)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      Get.back(); // tutup modal
                      if (createdTicket.value != null) {
                        Get.toNamed(Routes.ticketDetail,
                            arguments: createdTicket.value);
                      } else {
                        Get.toNamed(Routes.ticketDetail);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? const Color(0xFFFFD700) : Colors.white,
            fontSize: isTotal ? 15 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
