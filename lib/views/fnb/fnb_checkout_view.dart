// ignore_for_file: deprecated_member_use
// lib/views/fnb/fnb_checkout_view.dart
// Layar checkout pesanan F&B: Pilihan bioskop, metode antar, dan pembayaran (PB-028, PB-029)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/fnb_controller.dart';
import '../../models/cinema_model.dart';
import '../../models/fnb_item_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';

class FnbCheckoutView extends StatefulWidget {
  const FnbCheckoutView({super.key});

  @override
  State<FnbCheckoutView> createState() => _FnbCheckoutViewState();
}

class _FnbCheckoutViewState extends State<FnbCheckoutView> {
  final fnbCtrl = Get.find<FnbController>();

  @override
  void initState() {
    super.initState();
    fnbCtrl.autoDetectActiveTicket();
  }

  @override
  Widget build(BuildContext context) {
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
          'CHECKOUT F&B',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 17,
          ),
        ),
      ),
      body: Obx(() {
        if (fnbCtrl.cart.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('Keranjang Anda kosong',
                    style:
                        TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Kembali ke Menu'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Pilihan Lokasi Bioskop (PB-028) ──────────────────────────
              _buildSectionHeader(
                  '1. LOKASI BIOSKOP PENJUALAN', Icons.storefront_rounded),
              const SizedBox(height: 8),
              _buildCinemaSelector(),

              const SizedBox(height: 20),

              // ── 2. Metode Pengambilan (PB-028) ─────────────────────────────
              _buildSectionHeader(
                  '2. METODE PENGAMBILAN', Icons.delivery_dining_rounded),
              const SizedBox(height: 8),
              _buildPickupMethodSelector(),

              const SizedBox(height: 20),

              // ── 3. Ringkasan Item Pesanan (PB-027) ──────────────────────────
              _buildSectionHeader(
                  '3. DAFTAR PESANAN', Icons.receipt_long_rounded),
              const SizedBox(height: 8),
              _buildCartItemList(),

              const SizedBox(height: 20),

              // ── 4. Metode Pembayaran (PB-029) ──────────────────────────────
              _buildSectionHeader(
                  '4. METODE PEMBAYARAN', Icons.payment_rounded),
              const SizedBox(height: 8),
              _buildPaymentMethodSelector(),

              const SizedBox(height: 20),

              // ── 5. Rincian Biaya ───────────────────────────────────────────
              _buildPriceBreakdown(),

              const SizedBox(height: 32),

              // Tombol Konfirmasi Bayar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: fnbCtrl.isSubmittingOrder.value
                      ? null
                      : () async {
                          final order = await fnbCtrl.submitOrder();
                          if (order != null) {
                            Get.offNamed(Routes.fnbOrderDetail,
                                arguments: order);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: fnbCtrl.isSubmittingOrder.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Bayar Sekarang (${fnbCtrl.formattedGrandTotal})',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildCinemaSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CinemaModel>(
          isExpanded: true,
          dropdownColor: AppColors.surface,
          value: fnbCtrl.selectedCinema.value,
          hint: const Text('Pilih Bioskop',
              style: TextStyle(color: AppColors.textSecondary)),
          items: fnbCtrl.availableCinemas.map((cinema) {
            return DropdownMenuItem<CinemaModel>(
              value: cinema,
              child: Text(
                '${cinema.name} (${cinema.city})',
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) fnbCtrl.selectedCinema.value = val;
          },
        ),
      ),
    );
  }

  Widget _buildPickupMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            activeColor: AppColors.primary,
            title: const Text('Ambil di Counter Concession',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            subtitle: const Text('Ambil pesanan mandiri dengan E-Voucher QR',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: 'counter',
            groupValue: fnbCtrl.pickupMethod.value,
            onChanged: (val) => fnbCtrl.pickupMethod.value = val!,
          ),
          Divider(color: AppColors.border, height: 1),
          RadioListTile<String>(
            activeColor: AppColors.primary,
            title: const Text('Antar Langsung ke Studio & Kursi',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            subtitle: const Text(
                'Petugas akan mengantar pesanan ke tempat dudukmu',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: 'delivery',
            groupValue: fnbCtrl.pickupMethod.value,
            onChanged: (val) => fnbCtrl.pickupMethod.value = val!,
          ),
          if (fnbCtrl.pickupMethod.value == 'delivery')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Studio',
                        hintText: 'Misal: Studio 1',
                        labelStyle: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      controller: TextEditingController(
                          text: fnbCtrl.studioNumber.value)
                        ..selection = TextSelection.collapsed(
                            offset: fnbCtrl.studioNumber.value.length),
                      onChanged: (v) => fnbCtrl.studioNumber.value = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Nomor Kursi',
                        hintText: 'Misal: C4, C5',
                        labelStyle: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      controller:
                          TextEditingController(text: fnbCtrl.seatNumber.value)
                            ..selection = TextSelection.collapsed(
                                offset: fnbCtrl.seatNumber.value.length),
                      onChanged: (v) => fnbCtrl.seatNumber.value = v,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItemList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: fnbCtrl.cart.length,
        separatorBuilder: (_, __) =>
            Divider(color: AppColors.border, height: 1),
        itemBuilder: (context, index) {
          final itemId = fnbCtrl.cart.keys.elementAt(index);
          final qty = fnbCtrl.cart[itemId]!;
          final item =
              fnbCtrl.items.firstWhereOrNull((it) => it.id == itemId) ??
                  FnbItemModel(
                      id: itemId,
                      name: 'Item',
                      description: '',
                      price: 0,
                      category: 'snack');

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(item.formattedPrice,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: () => fnbCtrl.removeFromCart(item),
                    ),
                    Text('$qty',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: AppColors.primary, size: 20),
                      onPressed: () => fnbCtrl.addToCart(item),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final methods = [
      {'name': 'QRIS', 'desc': 'Scan instan via GoPay, OVO, BCA, Dana'},
      {'name': 'GoPay / OVO', 'desc': 'Pembayaran dompet digital otomatis'},
      {
        'name': 'BCA Virtual Account',
        'desc': 'Transfer bank verifikasi otomatis'
      },
      {
        'name': 'Mandiri Virtual Account',
        'desc': 'Transfer bank verifikasi otomatis'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: methods.map((m) {
          return RadioListTile<String>(
            activeColor: AppColors.primary,
            title: Text(m['name']!,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(m['desc']!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            value: m['name']!,
            groupValue: fnbCtrl.selectedPaymentMethod.value,
            onChanged: (val) => fnbCtrl.selectedPaymentMethod.value = val!,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal Makanan & Minuman',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(fnbCtrl.formattedSubtotal,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biaya Layanan & Pengemasan',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(
                fnbCtrl.serviceFee > 0 ? 'Rp 2.000' : 'Rp 0',
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.border, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(
                fnbCtrl.formattedGrandTotal,
                style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
