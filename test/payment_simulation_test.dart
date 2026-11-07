// test/payment_simulation_test.dart
// Pengujian unit simulasi pembayaran tiket bioskop (PB-021)

import 'package:cinemate/models/booking_order_model.dart';
import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/models/payment_method_model.dart';
import 'package:cinemate/models/showtime_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentMethodModel Tests (PB-021)', () {
    test('PaymentMethodModel should provide predefined VA, E-Wallet, and QRIS methods', () {
      final methods = PaymentMethodModel.predefinedMethods;

      expect(methods, isNotEmpty);

      final vaList = methods.where((m) => m.category == PaymentCategory.virtualAccount).toList();
      expect(vaList.length, greaterThanOrEqualTo(4)); // BCA, Mandiri, BRI, BNI
      expect(vaList.any((m) => m.name.contains('BCA')), true);
      expect(vaList.any((m) => m.accountNumber != null), true);

      final eWalletList = methods.where((m) => m.category == PaymentCategory.eWallet).toList();
      expect(eWalletList.length, greaterThanOrEqualTo(4)); // GoPay, OVO, DANA, ShopeePay
      expect(eWalletList.any((m) => m.name == 'GoPay'), true);

      final qrisList = methods.where((m) => m.category == PaymentCategory.qris).toList();
      expect(qrisList.length, 1);
      expect(qrisList.first.name, contains('QRIS'));
    });
  });

  group('BookingOrderModel Payment Status Tests (PB-021)', () {
    final movie = MovieModel(
      id: 533535,
      title: 'Deadpool & Wolverine',
      overview: 'Wade Wilson and Logan team up.',
      voteAverage: 7.9,
      voteCount: 1500,
      genreIds: [28, 35],
      popularity: 300.0,
      releaseDate: '2024-07-24',
    );

    final cinema = CinemaModel(
      id: 'cin-1',
      name: 'Metro Cinema Senayan',
      address: 'Jl. Asia Afrika No. 8, Jakarta Selatan',
      latitude: -6.2176,
      longitude: 106.8013,
      distanceKm: 2.6,
    );

    final showtime = ShowtimeModel(
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
    );

    test('Order should transition from pending to paid and record payment details', () {
      final pendingOrder = BookingOrderModel(
        id: 'ORD-PENDING-001',
        movie: movie,
        cinema: cinema,
        showtime: showtime,
        selectedSeats: ['C2', 'C3'],
        ticketPrice: 50000,
        serviceFeePerTicket: 3000,
        createdAt: DateTime(2026, 11, 7, 12, 0),
        status: 'pending',
      );

      expect(pendingOrder.status, 'pending');
      expect(pendingOrder.isPaid, false);
      expect(pendingOrder.isExpired, false);

      final paidTime = DateTime(2026, 11, 7, 12, 5);
      final paidOrder = pendingOrder.copyWith(
        status: 'paid',
        paymentMethod: 'BCA Virtual Account',
        paidAt: paidTime,
        paymentReference: 'PAY-20261107-1234',
      );

      expect(paidOrder.status, 'paid');
      expect(paidOrder.isPaid, true);
      expect(paidOrder.paymentMethod, 'BCA Virtual Account');
      expect(paidOrder.paymentReference, 'PAY-20261107-1234');
      expect(paidOrder.paidAt, paidTime);
    });

    test('Order should transition to expired if countdown timer runs out', () {
      final order = BookingOrderModel(
        id: 'ORD-TIMEOUT-001',
        movie: movie,
        cinema: cinema,
        showtime: showtime,
        selectedSeats: ['A1'],
        ticketPrice: 50000,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      final expiredOrder = order.copyWith(status: 'expired');
      expect(expiredOrder.isExpired, true);
      expect(expiredOrder.isPaid, false);
    });

    test('Order totalAmount should account for discount correctly', () {
      final orderWithPromo = BookingOrderModel(
        id: 'ORD-PROMO-001',
        movie: movie,
        cinema: cinema,
        showtime: showtime,
        selectedSeats: ['B1', 'B2'],
        ticketPrice: 50000,
        serviceFeePerTicket: 3000,
        discountAmount: 10000,
        createdAt: DateTime.now(),
      );

      // Subtotal: 100.000, Service Fee: 6.000, Discount: 10.000 -> Total: 96.000
      expect(orderWithPromo.subtotal, 100000);
      expect(orderWithPromo.totalServiceFee, 6000);
      expect(orderWithPromo.discountAmount, 10000);
      expect(orderWithPromo.totalAmount, 96000);
      expect(orderWithPromo.formattedTotalAmount, 'Rp 96.000');
    });
  });
}
