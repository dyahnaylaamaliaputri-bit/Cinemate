// lib/views/booking/payment_view.dart
// Tampilan Simulasi Pembayaran Tiket Bioskop (PB-021)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/payment_controller.dart';
import '../../models/payment_method_model.dart';
import '../../utils/app_colors.dart';

class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

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
              'Pembayaran Tiket',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Simulasi Pembayaran (PB-021)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Countdown Timer Banner (10 Menit)
            _buildCountdownBanner(),

            // 2. Konten Scrollable Pembayaran
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mini Order Summary
                    _buildOrderHeaderCard(),

                    const SizedBox(height: 16),

                    // Kategori Pilihan Metode Pembayaran (VA / E-Wallet / QRIS)
                    const Text(
                      'Pilih Metode Pembayaran',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCategoryTabs(),

                    const SizedBox(height: 16),

                    // Detail Metode Pembayaran Sesuai Kategori
                    Obx(() {
                      switch (controller.selectedCategory.value) {
                        case PaymentCategory.virtualAccount:
                          return _buildVirtualAccountSection();
                        case PaymentCategory.eWallet:
                          return _buildEWalletSection();
                        case PaymentCategory.qris:
                          return _buildQrisSection();
                      }
                    }),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 3. Sticky Bottom Bar Pembayaran
            _buildStickyPaymentBar(),
          ],
        ),
      ),
    );
  }

  /// Banner Timer Hitung Mundur 10 Menit
  Widget _buildCountdownBanner() {
    return Obx(() {
      final timer = controller.formattedTimer;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        color: const Color(0xFF2C1E1E),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.timer_rounded, color: AppColors.gold, size: 16),
                SizedBox(width: 8),
                Text(
                  'Batas Waktu Pembayaran',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Text(
                timer,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Ringkasan Singkat Pesanan
  Widget _buildOrderHeaderCard() {
    return Obx(() {
      final order = controller.order.value;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Poster Mini
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 64,
                color: AppColors.card,
                child: order.movie.posterUrl.isNotEmpty
                    ? Image.network(
                        order.movie.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.movie_creation_rounded,
                          color: AppColors.textDisabled,
                        ),
                      )
                    : const Icon(Icons.movie_creation_rounded,
                        color: AppColors.textDisabled),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.cinema.name} • ${order.showtime.hallName}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kursi: ${order.seatsLabel} (${order.seatCount} Tiket)',
                    style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total Tagihan',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  order.formattedTotalAmount,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// Tab Kategori Pembayaran (VA / E-Wallet / QRIS)
  Widget _buildCategoryTabs() {
    return Obx(() {
      final current = controller.selectedCategory.value;
      return Row(
        children: [
          _buildCategoryChip('Virtual Account', Icons.account_balance_rounded,
              PaymentCategory.virtualAccount, current),
          const SizedBox(width: 8),
          _buildCategoryChip('E-Wallet', Icons.account_balance_wallet_rounded,
              PaymentCategory.eWallet, current),
          const SizedBox(width: 8),
          _buildCategoryChip('QRIS', Icons.qr_code_scanner_rounded,
              PaymentCategory.qris, current),
        ],
      );
    });
  }

  Widget _buildCategoryChip(String label, IconData icon,
      PaymentCategory category, PaymentCategory active) {
    final isSelected = active == category;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => controller.selectCategory(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryDark.withValues(alpha: 0.3)
                : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryLight : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? AppColors.primaryLight
                      : AppColors.textSecondary,
                  size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Section Virtual Account
  Widget _buildVirtualAccountSection() {
    final vaMethods = controller.allMethods
        .where((m) => m.category == PaymentCategory.virtualAccount)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List Pilihan Bank
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: vaMethods.map((method) {
              final isSelected =
                  controller.selectedMethod.value.id == method.id;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => controller.selectMethod(method),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.card.withValues(alpha: 0.8)
                        : Colors.transparent,
                    border: Border(
                        bottom: BorderSide(
                            color: AppColors.divider.withValues(alpha: 0.4))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(method.icon,
                            color: isSelected ? AppColors.gold : Colors.white70,
                            size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method.description,
                              style: const TextStyle(
                                  color: AppColors.textDisabled, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.textDisabled,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Kotak Nomor Virtual Account
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nomor Virtual Account',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.selectedMethod.value.accountNumber ??
                        '8277 0812 3456 7890',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primaryDark.withValues(alpha: 0.3),
                      foregroundColor: AppColors.primaryLight,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Salin',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 11)),
                    onPressed: () => controller.copyToClipboard(
                      controller.selectedMethod.value.accountNumber ??
                          '8277 0812 3456 7890',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Petunjuk Pembayaran
        _buildInstructionsAccordion(
            controller.selectedMethod.value.instructions),
      ],
    );
  }

  /// 2. Section E-Wallet
  Widget _buildEWalletSection() {
    final eWalletMethods = controller.allMethods
        .where((m) => m.category == PaymentCategory.eWallet)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid E-Wallet Cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: eWalletMethods.length,
          itemBuilder: (context, index) {
            final method = eWalletMethods[index];
            final isSelected = controller.selectedMethod.value.id == method.id;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => controller.selectMethod(method),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryDark.withValues(alpha: 0.25)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primaryLight : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(method.icon,
                        color: isSelected ? AppColors.gold : Colors.white70,
                        size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        method.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Input Nomor HP E-Wallet
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nomor Akun ${controller.selectedMethod.value.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_android_rounded,
                      color: AppColors.gold, size: 20),
                  filled: true,
                  fillColor: AppColors.card,
                  hintText: '08xx-xxxx-xxxx',
                  hintStyle: const TextStyle(
                      color: AppColors.textDisabled, fontSize: 13),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppColors.success, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Simulasi 1-Tap bayar instan tanpa OTP riil',
                    style: TextStyle(color: AppColors.success, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _buildInstructionsAccordion(
            controller.selectedMethod.value.instructions),
      ],
    );
  }

  /// 3. Section QRIS
  Widget _buildQrisSection() {
    final order = controller.order.value;
    // Standar payload string QRIS simulasi
    final qrisPayload =
        '00020101021226680016ID.CO.CINEMATE.WWW0118936000000000000001520458125303360540${order.totalAmount}5802ID5917CINEMATE INDONESIA6007JAKARTA6304${order.id.hashCode.abs()}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Logo QRIS & Judul Merchant
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'QRIS',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2),
                ),
              ),
              const Text(
                'CINEMATE INDONESIA',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Render Kode QRIS Menggunakan qr_flutter
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: qrisPayload,
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

          const SizedBox(height: 16),

          Text(
            order.formattedTotalAmount,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'NMID: ID1020039847291 • Standar Pembayaran Nasional',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 10),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),

          _buildInstructionsAccordion(
              controller.selectedMethod.value.instructions),
        ],
      ),
    );
  }

  /// Accordion Petunjuk Pembayaran
  Widget _buildInstructionsAccordion(List<String> instructions) {
    if (instructions.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.info_outline_rounded,
              color: AppColors.gold, size: 18),
          title: const Text(
            'Petunjuk Pembayaran',
            style: TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: instructions.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}. ',
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sticky Bottom Bar Pembayaran
  Widget _buildStickyPaymentBar() {
    return Obx(() {
      final isProcessing = controller.isProcessing.value;
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
                  controller.order.value.formattedTotalAmount,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              onPressed: isProcessing ? null : controller.payNow,
              child: isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Bayar Sekarang',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    });
  }
}
