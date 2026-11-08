// lib/views/fnb/fnb_order_detail_view.dart
// Tampilan detail pesanan F&B, E-Voucher QR Code & Pelacakan Status (PB-029, PB-030)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/fnb_controller.dart';
import '../../models/fnb_order_model.dart';
import '../../utils/app_colors.dart';

class FnbOrderDetailView extends StatelessWidget {
  const FnbOrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final fnbCtrl = Get.find<FnbController>();
    final initialOrder = Get.arguments as FnbOrderModel?;

    if (initialOrder == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Pesanan F&B')),
        body: const Center(
            child: Text('Data pesanan tidak ditemukan.',
                style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'E-VOUCHER F&B',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 17,
          ),
        ),
      ),
      body: Obx(() {
        // Pantau order terbaru dari controller secara reaktif
        final order = fnbCtrl.userOrders
                .firstWhereOrNull((o) => o.id == initialOrder.id) ??
            initialOrder;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // ── E-Voucher Card ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: order.status == 'ready'
                            ? AppColors.primary
                            : order.status == 'completed'
                                ? Colors.green.shade800
                                : AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: order.status == 'ready'
                              ? AppColors.primaryLight
                              : order.status == 'completed'
                                  ? Colors.green
                                  : AppColors.gold,
                        ),
                      ),
                      child: Text(
                        order.statusLabel,
                        style: TextStyle(
                          color: order.status == 'completed'
                              ? Colors.white
                              : order.status == 'ready'
                                  ? Colors.white
                                  : AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: order.qrPayload,
                        version: QrVersions.auto,
                        size: 160.0,
                        backgroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'KODE PENGAMBILAN',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.pickupCode,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: AppColors.border, height: 1),
                    ),

                    // Info Bioskop & Metode
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            color: AppColors.gold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.cinemaName,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text(order.pickupMethodLabel,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Status Tracking Stepper ─────────────────────────────────────
              _buildStatusTracker(order.status),

              const SizedBox(height: 20),

              // ── Rincian Item ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RINCIAN PESANAN',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 12),
                    ...order.items.map((it) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${it.quantity}x ${it.name}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13)),
                            Text(it.formattedSubtotal,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                    Divider(color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(order.formattedTotalPrice,
                            style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Tombol Simulasi Petugas Bioskop (PB-030) ────────────────────
              OutlinedButton.icon(
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: Text(
                  order.status == 'processing'
                      ? 'Simulasi Petugas: Tandai Siap Diambil'
                      : order.status == 'ready'
                          ? 'Simulasi Petugas: Tandai Selesai'
                          : 'Simulasi: Reset ke Disiapkan',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => fnbCtrl.advanceOrderStatus(order.id),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusTracker(String currentStatus) {
    int currentStep = 0;
    if (currentStatus == 'ready') currentStep = 1;
    if (currentStatus == 'completed') currentStep = 2;

    final steps = [
      {'title': 'Disiapkan', 'desc': 'Koki menyiapkan pesanan'},
      {'title': 'Siap Diambil', 'desc': 'Di counter atau siap diantar'},
      {'title': 'Selesai', 'desc': 'Pesanan telah diterima'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STATUS PESANAN',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.8)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (idx) {
              final isDone = idx <= currentStep;
              final isCurrent = idx == currentStep;

              return Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          isDone ? AppColors.primary : AppColors.inputFill,
                      child: Icon(
                        isDone ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[idx]['title']!,
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (idx < steps.length - 1)
                      Container(
                        width: 16,
                        height: 2,
                        color: idx < currentStep
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
