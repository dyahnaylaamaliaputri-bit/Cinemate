// lib/views/ticket/ticket_detail_view.dart
// Halaman Detail E-Ticket bioskop dengan QR Code & Akses Offline (PB-022, PB-024, PB-025)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/ticket_detail_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';

class TicketDetailView extends GetView<TicketDetailController> {
  const TicketDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-Ticket Bioskop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Tunjukkan kode QR saat masuk studio (PB-022)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Obx(() {
            final isTicketActive = controller.ticket.value.isTicketActive;
            if (!isTicketActive) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.sensor_occupied_rounded, color: AppColors.gold),
              tooltip: 'Simulasi Check-in Studio (PB-025)',
              onPressed: () => _showCheckInDialog(context),
            );
          }),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
            onPressed: () {
              Get.snackbar(
                'Bagikan Tiket',
                'Tautan tiket digital ${controller.ticket.value.bookingCode} siap dibagikan!',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.card,
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Badge Mode Offline Ready (PB-024)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_pin_rounded, color: AppColors.success, size: 16),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tersimpan Offline di Perangkat (Offline Ready)',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Kartu E-Ticket Utama
              _buildETicketCard(),

              const SizedBox(height: 24),

              // Tombol Navigasi Bawah
              Obx(() {
                final isHistory = controller.ticket.value.isTicketHistory;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Get.until((route) => route.settings.name == Routes.dashboard);
                        },
                        child: const Text('Ke Beranda', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isHistory
                          ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Pesan Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Get.toNamed(Routes.bookByCinema);
                              },
                            )
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('Unduh PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Get.snackbar(
                                  'Unduh Berhasil',
                                  'E-ticket ${controller.ticket.value.bookingCode} berhasil disimpan ke dokumen.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.card,
                                  colorText: Colors.white,
                                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                                );
                              },
                            ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog Konfirmasi Simulasi Check-in
  void _showCheckInDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.gold),
            SizedBox(width: 10),
            Text('Simulasi Check-in', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Tandai tiket ${controller.ticket.value.bookingCode} telah dipindai di pintu studio? Tiket akan otomatis dipindahkan ke tab Riwayat (PB-025).',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              controller.simulateCheckIn();
            },
            child: const Text('Pindai & Masuk'),
          ),
        ],
      ),
    );
  }

  /// Kartu E-Ticket Fisik Digital
  Widget _buildETicketCard() {
    return Obx(() {
      final ticket = controller.ticket.value;
      final isHistory = ticket.isTicketHistory;

      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Bioskop & Pengalaman Studio
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF131326),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.movie_rounded, color: AppColors.primaryLight, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        ticket.cinemaName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      ticket.experience,
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

            // Info Film
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 65,
                      height: 90,
                      color: AppColors.card,
                      child: ticket.posterUrl.isNotEmpty
                          ? Image.network(
                              ticket.posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.movie_creation_rounded,
                                color: AppColors.textDisabled,
                                size: 32,
                              ),
                            )
                          : const Icon(Icons.movie_creation_rounded, color: AppColors.textDisabled),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.movieTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticket.cinemaAddress,
                          style: const TextStyle(color: AppColors.textDisabled, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoChip(Icons.meeting_room_rounded, ticket.hallName),
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.event_seat_rounded, 'Kursi: ${ticket.seatsLabel}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Baris Jadwal (Tanggal & Waktu)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('TANGGAL', style: TextStyle(color: AppColors.textDisabled, fontSize: 10, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        ticket.showDate,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 26, color: AppColors.divider),
                  Column(
                    children: [
                      const Text('JAM TAYANG', style: TextStyle(color: AppColors.textDisabled, fontSize: 10, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket.showTime} WIB',
                        style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 26, color: AppColors.divider),
                  Column(
                    children: [
                      const Text('TOTAL TIKET', style: TextStyle(color: AppColors.textDisabled, fontSize: 10, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket.seatCount} Kursi',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sobekan Perforasi Tiket
            _buildTicketPerforation(),

            // Bagian QR Code (PB-022)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // QR Code Box
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Opacity(
                          opacity: isHistory ? 0.35 : 1.0,
                          child: QrImageView(
                            data: ticket.qrData,
                            version: QrVersions.auto,
                            size: 190.0,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0A0A0A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                        ),
                      ),
                      if (isHistory)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E2E3E).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                ticket.historyStatusLabel.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Kode Booking Unik
                  const Text(
                    'KODE BOOKING',
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ticket.bookingCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AppColors.primaryLight, size: 18),
                        onPressed: controller.copyBookingCode,
                        tooltip: 'Salin Kode Booking',
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(
                    isHistory
                        ? 'Tiket ini telah digunakan untuk menonton atau masa berlakunya telah berakhir.'
                        : 'Pindai kode QR ini pada gerbang masuk bioskop untuk cetak tiket fisik atau langsung masuk studio.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 12),

                  // Detail Transaksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        ticket.formattedPrice,
                        style: const TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status Tiket', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isHistory ? AppColors.textDisabled : AppColors.success).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isHistory ? AppColors.textDisabled : AppColors.success),
                        ),
                        child: Text(
                          isHistory ? ticket.historyStatusLabel.toUpperCase() : ticket.status.toUpperCase(),
                          style: TextStyle(
                            color: isHistory ? AppColors.textDisabled : AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 12),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Efek lekukan sobekan perforasi tiket khas bioskop
  Widget _buildTicketPerforation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const circleSize = 20.0;
        final dashWidth = 6.0;
        final dashSpace = 4.0;
        final totalWidth = constraints.maxWidth - (circleSize * 2);
        final dashCount = (totalWidth / (dashWidth + dashSpace)).floor();

        return SizedBox(
          height: circleSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Garis Putus-putus
              Positioned(
                left: circleSize,
                right: circleSize,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashCount,
                    (_) => Container(
                      width: dashWidth,
                      height: 1.5,
                      color: AppColors.divider,
                    ),
                  ),
                ),
              ),

              // Lekukan Kiri
              Positioned(
                left: -(circleSize / 2),
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Lekukan Kanan
              Positioned(
                right: -(circleSize / 2),
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
