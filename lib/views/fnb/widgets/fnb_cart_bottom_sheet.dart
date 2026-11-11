// lib/views/fnb/widgets/fnb_cart_bottom_sheet.dart
// Modal Bottom Sheet untuk mengelola keranjang F&B (PB-027)
// Menampilkan item terpilih, kuantitas stepper, catatan per menu, dan kalkulasi subtotal

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/fnb_controller.dart';
import '../../../models/fnb_item_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_colors.dart';

class FnbCartBottomSheet extends StatelessWidget {
  const FnbCartBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FnbCartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fnbCtrl = Get.find<FnbController>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle & Header ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => Text(
                        'Keranjang Belanja (${fnbCtrl.totalCartItems})',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      )),
                ),
                TextButton.icon(
                  onPressed: () => _confirmClearCart(context, fnbCtrl),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 17, color: AppColors.error),
                  label: const Text(
                    'Kosongkan',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),

          // ── Daftar Item Keranjang ─────────────────────────────────────────
          Flexible(
            child: Obx(() {
              final detailedItems = fnbCtrl.cartItemsDetailed;

              if (detailedItems.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.remove_shopping_cart_outlined,
                          size: 56, color: AppColors.textSecondary),
                      const SizedBox(height: 14),
                      const Text(
                        'Keranjang Anda Masih Kosong',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pilih camilan atau minuman dari katalog untuk menambahkannya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: detailedItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = detailedItems[index];
                  final FnbItemModel item = data['item'] as FnbItemModel;
                  final int qty = data['quantity'] as int;
                  final String note = data['note'] as String;

                  return _buildCartItemTile(context, fnbCtrl, item, qty, note);
                },
              );
            }),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // ── Rincian Biaya & Tombol Checkout ───────────────────────────────
          Obx(() {
            if (fnbCtrl.cart.isEmpty) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.card,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal Menu',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Text(
                          fnbCtrl.formattedSubtotal,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Biaya Layanan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Biaya Layanan Aplikasi',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Text(
                          fnbCtrl.formattedServiceFee,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 10),

                    // Total Tagihan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          fnbCtrl.formattedGrandTotal,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tombol Lanjut ke Checkout
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Get.toNamed(Routes.fnbCheckout);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lanjut ke Pemesanan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(BuildContext context, FnbController fnbCtrl,
      FnbItemModel item, int qty, String note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Menu
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.category == 'drink'
                      ? Icons.local_drink_rounded
                      : item.category == 'combo'
                          ? Icons.fastfood_rounded
                          : item.category == 'food'
                              ? Icons.dinner_dining_rounded
                              : Icons.lunch_dining_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Nama & Harga Satuan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.formattedPrice,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Stepper Quantity
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => fnbCtrl.removeFromCart(item),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.remove,
                            size: 15, color: AppColors.textPrimary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '$qty',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => fnbCtrl.addToCart(item),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child:
                            Icon(Icons.add, size: 15, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Subtotal per item & Tombol Tambah Catatan (PB-027)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _showNoteDialog(context, fnbCtrl, item, note),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        note.isNotEmpty
                            ? Icons.edit_note_rounded
                            : Icons.add_comment_outlined,
                        size: 15,
                        color: note.isNotEmpty
                            ? AppColors.primaryLight
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        note.isNotEmpty ? 'Catatan: $note' : '+ Tambah Catatan',
                        style: TextStyle(
                          color: note.isNotEmpty
                              ? AppColors.primaryLight
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontStyle: note.isNotEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'Subtotal: ${fnbCtrl.cartItemsDetailed.firstWhereOrNull((d) => (d['item'] as FnbItemModel).id == item.id)?['formattedSubtotal'] ?? ''}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, FnbController fnbCtrl,
      FnbItemModel item, String currentNote) {
    final noteController = TextEditingController(text: currentNote);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Catatan: ${item.name}',
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instruksi khusus penyajian (contoh: ekstra saus, kurangi es, pisahkan bumbu):',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              autofocus: true,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tulis catatan di sini...',
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (currentNote.isNotEmpty)
            TextButton(
              onPressed: () {
                fnbCtrl.setItemNote(item.id, '');
                Navigator.pop(ctx);
              },
              child: const Text('Hapus Catatan',
                  style: TextStyle(color: AppColors.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              fnbCtrl.setItemNote(item.id, noteController.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context, FnbController fnbCtrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kosongkan Keranjang?',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        content: const Text(
          'Seluruh item dan catatan makanan & minuman akan dihapus dari keranjang.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              fnbCtrl.clearCart();
              Navigator.pop(ctx);
              Navigator.pop(context); // close bottom sheet
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Kosongkan'),
          ),
        ],
      ),
    );
  }
}
