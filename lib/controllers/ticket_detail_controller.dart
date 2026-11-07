// lib/controllers/ticket_detail_controller.dart
// Controller untuk melihat detail E-Ticket dan QR Code (PB-022)

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/ticket_model.dart';

class TicketDetailController extends GetxController {
  late final Rx<TicketModel> ticket;

  @override
  void onInit() {
    super.onInit();
    _initTicket();
  }

  void _initTicket() {
    final args = Get.arguments;
    if (args is TicketModel) {
      ticket = Rx<TicketModel>(args);
    } else {
      // Fallback demo ticket
      ticket = Rx<TicketModel>(
        TicketModel(
          id: 'TKT-DEMO-001',
          bookingCode: 'CNM-78429',
          userId: 'usr-1',
          showtimeId: 'st-101',
          movieId: 533535,
          movieTitle: 'Deadpool & Wolverine',
          posterPath: '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
          cinemaId: 'cin-1',
          cinemaName: 'Metro Cinema Senayan',
          cinemaAddress: 'Jl. Asia Afrika No. 8, Jakarta Selatan',
          hallName: 'Studio 1',
          experience: 'Regular 2D',
          showDate: '2026-11-07',
          showTime: '14:00',
          seats: ['C2', 'C3'],
          totalPrice: 106000,
          qrData: 'CINEMATE:CNM-78429:2026-11-07:14:00:C2,C3',
          status: 'paid',
          paymentMethod: 'QRIS Bersama',
          paymentReference: 'PAY-28693526',
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Salin kode booking tiket
  void copyBookingCode() {
    Clipboard.setData(ClipboardData(text: ticket.value.bookingCode));
    Get.snackbar(
      'Kode Booking Tersalin',
      'Kode ${ticket.value.bookingCode} berhasil disalin ke clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF16213E),
      colorText: const Color(0xFFFFFFFF),
      duration: const Duration(seconds: 2),
    );
  }
}
