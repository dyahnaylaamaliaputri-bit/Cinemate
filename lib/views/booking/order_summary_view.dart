// lib/views/booking/order_summary_view.dart
// Tampilan Ringkasan Pesanan / Order Summary tiket bioskop (PB-020)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/order_summary_controller.dart';
import '../../utils/app_colors.dart';

class OrderSummaryView extends GetView<OrderSummaryController> {
  const OrderSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Pesanan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Periksa kembali rincian tiket bioskop Anda (PB-020)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner Countdown Timer Pemesanan (10 menit)
            _buildCountdownBanner(),

            // Konten Tiket Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Kartu Tiket Sinema
                    _buildCinemaTicketCard(),

                    const SizedBox(height: 16),

                    // Input Promo Voucher
                    _buildVoucherCard(),

                    const SizedBox(height: 16),

                    // Kartu Informasi Pemesan
                    _buildUserInfoCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Bar
            _buildBottomPaymentBar(),
          ],
        ),
      ),
    );
  }

  /// Banner Timer Hitung Mundur Sisa Waktu Reservasi
  Widget _buildCountdownBanner() {
    return Obx(() {
      final timerText = controller.formattedTimer;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        color: const Color(0xFF2C1E1E),
        child: Row(
          children: [
            const Icon(Icons.access_time_filled_rounded,
                color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Selesaikan pesanan dalam ',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              timerText,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Kartu Tiket Bioskop Bergaya Perforated Cinema Ticket
  Widget _buildCinemaTicketCard() {
    return Obx(() {
      final order = controller.order.value;
      final movie = order.movie;
      final cinema = order.cinema;
      final showtime = order.showtime;

      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Info Film & Poster
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 70,
                      height: 100,
                      color: AppColors.card,
                      child: movie.posterUrl.isNotEmpty
                          ? Image.network(
                              movie.posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.movie_creation_rounded,
                                color: AppColors.textDisabled,
                                size: 36,
                              ),
                            )
                          : const Icon(
                              Icons.movie_creation_rounded,
                              color: AppColors.textDisabled,
                              size: 36,
                            ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Detail Film
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.gold, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              movie.formattedRating,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${movie.releaseYear} • ${movie.formattedDuration}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryDark.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            showtime.experience,
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.divider, height: 1),

            // 2. Info Bioskop, Jadwal, Studio & Kursi
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.location_on_rounded,
                    'Bioskop',
                    cinema.name,
                    subtitle: cinema.address,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.calendar_month_rounded,
                    'Tanggal & Jam',
                    '${order.formattedShowDate} • ${showtime.showTime} WIB',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.meeting_room_rounded,
                    'Studio / Hall',
                    '${showtime.hallName} (${showtime.experience})',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.event_seat_rounded,
                    'Nomor Kursi',
                    order.seatsLabel,
                    highlightText: true,
                    trailingBadge: '${order.seatCount} Kursi',
                  ),
                  if (order.fnbItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.fastfood_rounded,
                      'F&B Tambahan',
                      order.fnbItems
                          .map((e) => '${e.name} x${e.quantity}')
                          .join(', '),
                      trailingBadge: '${order.fnbItems.length} Item',
                    ),
                  ],
                ],
              ),
            ),

            // 3. Perforated Dashed Line Divider dengan Notch Tiket
            _buildTicketPerforation(),

            // 4. Rincian Biaya (Price Breakdown)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian Biaya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCostRow(
                    'Harga Tiket (${order.formattedTicketPrice} x ${order.seatCount})',
                    order.formattedSubtotal,
                  ),
                  const SizedBox(height: 8),
                  _buildCostRow(
                    'Biaya Layanan (Rp 3.000 x ${order.seatCount})',
                    order.formattedServiceFee,
                  ),
                  if (order.fnbItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildCostRow(
                      'Camilan & Minuman F&B',
                      order.formattedFnbTotal,
                    ),
                  ],
                  if (controller.isVoucherApplied.value) ...[
                    const SizedBox(height: 8),
                    _buildCostRow(
                      'Diskon Promo Voucher',
                      '- ${controller.formattedDiscount}',
                      isDiscount: true,
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppColors.divider, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        controller.formattedFinalTotalAmount,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Garis putus-putus berlubang di sisi kanan & kiri layaknya sobekan tiket bioskop
  Widget _buildTicketPerforation() {
    return Row(
      children: [
        // Cutout Kiri
        ClipRRect(
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(12)),
          child: Container(
            width: 12,
            height: 24,
            color: AppColors.background,
          ),
        ),
        // Dashed line
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = constraints.constrainWidth();
              const dashWidth = 6.0;
              const dashHeight = 1.0;
              final dashCount = (boxWidth / (2 * dashWidth)).floor();
              return Flex(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                direction: Axis.horizontal,
                children: List.generate(dashCount, (_) {
                  return const SizedBox(
                    width: dashWidth,
                    height: dashHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.border),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        // Cutout Kanan
        ClipRRect(
          borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(12)),
          child: Container(
            width: 12,
            height: 24,
            color: AppColors.background,
          ),
        ),
      ],
    );
  }

  /// Baris Rincian Detail Pemesanan
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    String? subtitle,
    bool highlightText = false,
    String? trailingBadge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: highlightText ? AppColors.primaryLight : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AppColors.textDisabled, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailingBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              trailingBadge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  /// Baris Komponen Biaya
  Widget _buildCostRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDiscount ? AppColors.success : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount ? AppColors.success : Colors.white,
            fontSize: 13,
            fontWeight: isDiscount ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Input Voucher Promo Diskon
  Widget _buildVoucherCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_offer_rounded, color: AppColors.gold, size: 16),
              SizedBox(width: 8),
              Text(
                'Voucher / Kode Promo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() {
            if (controller.isVoucherApplied.value) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Promo Aktif: ${controller.voucherCodeController.text} (-${controller.formattedDiscount})',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: controller.removeVoucher,
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 18),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.voucherCodeController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Cth: CINEMATEHEMAT',
                      hintStyle: const TextStyle(
                          color: AppColors.textDisabled, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.primaryLight),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: controller.applyVoucher,
                  child: const Text('Gunakan',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            );
          }),
          Obx(() {
            if (controller.voucherError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  controller.voucherError.value,
                  style: const TextStyle(color: AppColors.error, fontSize: 11),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// Kartu Informasi Pemesan
  Widget _buildUserInfoCard() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_rounded,
                    color: AppColors.textSecondary, size: 16),
                SizedBox(width: 8),
                Text(
                  'Informasi Pemesan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nama:',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text(
                  controller.userName.value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Email:',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text(
                  controller.userEmail.value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('E-Ticket:',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text(
                  'Instan di Tab Tiket (Offline Ready)',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// Sticky Bottom Bar: Total Tagihan & Tombol Lanjut ke Pembayaran
  Widget _buildBottomPaymentBar() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Tagihan',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.formattedFinalTotalAmount,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.payment_rounded, size: 18),
              label: const Text(
                'Lanjut Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: controller.proceedToPayment,
            ),
          ],
        ),
      );
    });
  }
}
