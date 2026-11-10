// lib/views/dashboard/tabs/fnb_tab.dart
// Tab Pesan Makanan / F&B: Katalog camilan dan minuman bioskop & Riwayat E-Voucher (PB-026, PB-027, PB-030)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/fnb_controller.dart';
import '../../../models/fnb_item_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_colors.dart';
import '../../widgets/shimmer_loading.dart';

class FnbTab extends StatefulWidget {
  const FnbTab({super.key});

  @override
  State<FnbTab> createState() => _FnbTabState();
}

class _FnbTabState extends State<FnbTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final fnbCtrl = Get.put(FnbController());

  final categories = ['Semua', 'Snack', 'Drink', 'Combo', 'Food'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'PESAN MAKANAN & MINUMAN',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 17,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(text: 'Katalog Menu 🍿'),
            Obx(() => Tab(
                  text: 'Pesanan Saya (${fnbCtrl.userOrders.length})',
                )),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildCatalogTab(),
              _buildOrdersTab(),
            ],
          ),

          // ── Floating Cart Summary Bar (PB-027) ─────────────────────────────
          Obx(() {
            if (fnbCtrl.cart.isEmpty) return const SizedBox.shrink();

            return Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${fnbCtrl.totalCartItems} Item Dipilih',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            fnbCtrl.formattedGrandTotal,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Get.toNamed(Routes.fnbCheckout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Checkout →',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
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

  // ── Tab 1: Katalog Menu ───────────────────────────────────────────────────

  Widget _buildCatalogTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => fnbCtrl.fetchFnbCatalog(forceRefresh: true),
      child: Column(
        children: [
          // Banner Offline-First Hive Cache (PB-026)
          Obx(() {
            final cached = fnbCtrl.lastCacheTime.value;
            final timeStr = cached != null
                ? '${cached.hour.toString().padLeft(2, '0')}:${cached.minute.toString().padLeft(2, '0')} WIB'
                : 'Tersimpan';

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1C12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.offline_bolt_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Katalog F&B Offline-First',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Hive Local Cache',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fnbCtrl.items.length} menu tersimpan di Hive ($timeStr). Tanpa koneksi database online.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.gold, size: 18),
                    tooltip: 'Segarkan Cache Hive',
                    onPressed: () =>
                        fnbCtrl.fetchFnbCatalog(forceRefresh: true),
                  ),
                ],
              ),
            );
          }),

          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Obx(() => TextField(
                  controller: fnbCtrl.searchController,
                  onChanged: fnbCtrl.setSearchQuery,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Cari popcorn, nachos, cola, combo...',
                    hintStyle: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary, size: 20),
                    suffixIcon: fnbCtrl.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textSecondary, size: 18),
                            onPressed: fnbCtrl.clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                )),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Obx(() => Row(
                  children: categories.map((cat) {
                    final isSelected = fnbCtrl.selectedCategory.value == cat;
                    final count = fnbCtrl.getCategoryCount(cat);
                    final label = count > 0 ? '$cat ($count)' : cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(label),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: AppColors.card,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        onSelected: (_) => fnbCtrl.setCategory(cat),
                      ),
                    );
                  }).toList(),
                )),
          ),

          const SizedBox(height: 6),

          // Items List with Skeleton Shimmer (PB-026)
          Expanded(
            child: Obx(() {
              if (fnbCtrl.isLoading.value) {
                return const FnbListSkeleton();
              }

              if (fnbCtrl.filteredItems.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fastfood_outlined,
                              size: 48, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Menu Tidak Ditemukan',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fnbCtrl.searchQuery.value.isNotEmpty
                              ? 'Tidak ada menu yang cocok dengan "${fnbCtrl.searchQuery.value}".'
                              : 'Tidak ada menu pada kategori ${fnbCtrl.selectedCategory.value}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            fnbCtrl.clearSearch();
                            fnbCtrl.setCategory('Semua');
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Reset Pencarian & Filter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, fnbCtrl.cart.isNotEmpty ? 90 : 20),
                itemCount: fnbCtrl.filteredItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = fnbCtrl.filteredItems[index];
                  return _buildItemCard(item);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(FnbItemModel item) {
    return Obx(() {
      final qty = fnbCtrl.getItemQuantity(item.id);

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: qty > 0
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon / Foto Kategori
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
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
                size: 32,
              ),
            ),
            const SizedBox(width: 12),

            // Deskripsi Item
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.categoryLabel,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.formattedPrice,
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Tombol Tambah / Counter Quantity
            if (qty == 0)
              ElevatedButton(
                onPressed: () => fnbCtrl.addToCart(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(60, 34),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('+ Tambah',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              )
            else
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
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.remove,
                            size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$qty',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: () => fnbCtrl.addToCart(item),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child:
                            Icon(Icons.add, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  // ── Tab 2: Pesanan Saya (PB-030) ──────────────────────────────────────────

  Widget _buildOrdersTab() {
    return Obx(() {
      if (fnbCtrl.isLoadingOrders.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }

      if (fnbCtrl.userOrders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 14),
              const Text('Belum ada pesanan F&B',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
              const SizedBox(height: 6),
              const Text('Pesan popcorn dan minuman favoritmu sekarang!',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: fnbCtrl.fetchUserOrders,
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: fnbCtrl.userOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = fnbCtrl.userOrders[index];
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Get.toNamed(Routes.fnbOrderDetail, arguments: order),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.pickupCode,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: order.status == 'ready'
                                ? AppColors.primary
                                : order.status == 'completed'
                                    ? Colors.green.shade800
                                    : AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.statusLabel,
                            style: TextStyle(
                              color: order.status == 'completed' ||
                                      order.status == 'ready'
                                  ? Colors.white
                                  : AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(order.cinemaName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${order.items.length} Menu • ${order.formattedTotalPrice}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.pickupMethodLabel,
                            style: const TextStyle(
                                color: AppColors.gold, fontSize: 11)),
                        const Text('Buka Voucher →',
                            style: TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
