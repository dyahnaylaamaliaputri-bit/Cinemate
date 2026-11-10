// lib/views/booking/select_seat_view.dart
// Tampilan pemilihan kursi bioskop interaktif (PB-020)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/booking_seat_controller.dart';
import '../../models/fnb_item_model.dart';
import '../../models/seat_model.dart';
import '../../utils/app_colors.dart';

class SelectSeatView extends GetView<BookingSeatController> {
  const SelectSeatView({super.key});

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.movie.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${controller.cinema.name} • ${controller.showtime.hallName}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Info Jadwal
            _buildShowtimeInfoBar(),

            // Seating Plan & Legend
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    // Layar Bioskop (Curved Screen)
                    _buildCinemaScreen(),

                    const SizedBox(height: 36),

                    // Grid Kursi
                    _buildSeatsGrid(),

                    const SizedBox(height: 36),

                    // Keterangan / Legend
                    _buildLegend(),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Bar
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  /// Bar info tanggal, jam, dan studio
  Widget _buildShowtimeInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface.withValues(alpha: 0.6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.gold),
              const SizedBox(width: 6),
              Text(
                '${controller.showtime.showDate} • ${controller.showtime.showTime} WIB',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Text(
              controller.showtime.experience,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Representasi Layar Bioskop Melengkung
  Widget _buildCinemaScreen() {
    return Column(
      children: [
        CustomPaint(
          size: const Size(double.infinity, 36),
          painter: _ScreenArcPainter(),
        ),
        const SizedBox(height: 6),
        const Text(
          'LAYAR BIOSKOP',
          style: TextStyle(
            color: AppColors.textDisabled,
            fontSize: 11,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Grid baris kursi bioskop (A-G) dengan walkway di tengah
  Widget _buildSeatsGrid() {
    return Obx(() {
      return Column(
        children: controller.rows.map((rowLetter) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Label Baris Kiri
                SizedBox(
                  width: 16,
                  child: Text(
                    rowLetter,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(width: 4),

                // Kursi Sisi Kiri (1-4)
                ...List.generate(4, (index) {
                  final col = index + 1;
                  final seatId = '$rowLetter$col';
                  final seat = controller.seatsMap[seatId];
                  return _buildSeatItem(seatId, seat);
                }),

                // Lorong Jalan (Walkway) di tengah
                const SizedBox(width: 14),

                // Kursi Sisi Kanan (5-8)
                ...List.generate(4, (index) {
                  final col = index + 5;
                  final seatId = '$rowLetter$col';
                  final seat = controller.seatsMap[seatId];
                  return _buildSeatItem(seatId, seat);
                }),

                const SizedBox(width: 4),

                // Label Baris Kanan
                SizedBox(
                  width: 16,
                  child: Text(
                    rowLetter,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  /// Widget satu kursi interaktif
  Widget _buildSeatItem(String seatId, SeatModel? seat) {
    if (seat == null) {
      return const SizedBox(width: 30, height: 30);
    }

    final isSelected = seat.isSelected;
    final isReserved = seat.isReserved;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isReserved) {
      bgColor = const Color(0xFF1F1F2E);
      borderColor = Colors.transparent;
      textColor = AppColors.textDisabled;
    } else if (isSelected) {
      bgColor = AppColors.primary;
      borderColor = AppColors.primaryLight;
      textColor = Colors.white;
    } else {
      bgColor = AppColors.card;
      borderColor = AppColors.border;
      textColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: () => controller.toggleSeat(seatId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isReserved
              ? const Icon(Icons.close_rounded,
                  size: 13, color: AppColors.textDisabled)
              : Text(
                  '${seat.column}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  /// Legend / Panduan Warna Kursi
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Tersedia', AppColors.card, AppColors.border),
          _buildLegendItem(
              'Dipilih', AppColors.primary, AppColors.primaryLight),
          _buildLegendItem(
              'Terisi', const Color(0xFF1F1F2E), Colors.transparent,
              hasIcon: true),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, Color border,
      {bool hasIcon = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
          child: hasIcon
              ? const Icon(Icons.close_rounded,
                  size: 12, color: AppColors.textDisabled)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  /// Sticky Bottom Bar: Rincian Kursi Terpilih & Tombol Lanjut ke Order Summary
  Widget _buildBottomBar(BuildContext context) {
    return Obx(() {
      final hasSelected = controller.selectedSeats.isNotEmpty;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Baris Kursi Terpilih & Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSelected
                            ? 'Kursi (${controller.selectedSeats.length}): ${controller.selectedSeatsLabel}'
                            : 'Pilih minimal 1 kursi bioskop',
                        style: TextStyle(
                          color: hasSelected
                              ? Colors.white
                              : AppColors.textDisabled,
                          fontSize: 13,
                          fontWeight:
                              hasSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasSelected
                            ? controller.formattedSubtotal
                            : 'Harga @ ${controller.showtime.formattedPrice}',
                        style: TextStyle(
                          color: hasSelected
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        hasSelected ? AppColors.primary : AppColors.card,
                    foregroundColor:
                        hasSelected ? Colors.white : AppColors.textDisabled,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: hasSelected ? 4 : 0,
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text(
                    'Ringkasan Pesanan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed:
                      hasSelected ? () => _showFnbAddonModal(context) : null,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showFnbAddonModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FnbAddonBottomSheet(controller: controller),
    );
  }
}

/// Modal Bottom Sheet Tambah Makanan Opsional sebelum Order Summary (PB-032 / FR-028)
class _FnbAddonBottomSheet extends StatelessWidget {
  final BookingSeatController controller;

  const _FnbAddonBottomSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final seedItems = FnbItemModel.seedItems.take(5).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🍿', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mau Tambah Camilan Nonton?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pesan sekarang & ambil di counter concession.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List Snack & Minuman Cepat
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: seedItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = seedItems[index];
                return Obx(() {
                  final qty = controller.selectedFnbItems[item.id] ?? 0;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: qty > 0 ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.formattedPrice,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Stepper + / -
                        Row(
                          children: [
                            if (qty > 0) ...[
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: AppColors.textSecondary, size: 22),
                                onPressed: () =>
                                    controller.removeFnbItem(item.id),
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: AppColors.primary, size: 24),
                              onPressed: () => controller.addFnbItem(item.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Obx(() {
            final fnbTotal = controller.fnbAddonTotal;
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      controller.proceedToOrderSummary(directFnbItems: []);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Lewati',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      controller.proceedToOrderSummary();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      fnbTotal > 0
                          ? 'Lanjut (+ ${controller.formattedFnbAddonTotal})'
                          : 'Lanjut Tanpa Camilan',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Painter untuk melukis lengkungan layar bioskop
class _ScreenArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // Glowing arc screen
    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(rect, 3.14159 * 1.15, 3.14159 * 0.7, false, glowPaint);
    canvas.drawArc(rect, 3.14159 * 1.15, 3.14159 * 0.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
