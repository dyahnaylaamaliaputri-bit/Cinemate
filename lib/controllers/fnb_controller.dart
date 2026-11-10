// lib/controllers/fnb_controller.dart
// Controller untuk keranjang, katalog F&B, dan pelacakan pesanan (PB-026, PB-027, PB-028, PB-029, PB-030)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/cinema_model.dart';
import '../models/fnb_item_model.dart';
import '../models/fnb_order_model.dart';
import '../services/cinema_service.dart';
import '../services/fnb_service.dart';
import 'auth_controller.dart';
import 'tickets_controller.dart';

class FnbController extends GetxController {
  final FnbService _service;
  final CinemaService _cinemaService;

  FnbController({
    FnbService? service,
    CinemaService? cinemaService,
  })  : _service = service ?? FnbService(),
        _cinemaService = cinemaService ?? CinemaService();

  // ── State Katalog ─────────────────────────────────────────────────────────
  final items = <FnbItemModel>[].obs;
  final filteredItems = <FnbItemModel>[].obs;
  final selectedCategory = 'Semua'.obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final lastCacheTime = Rx<DateTime?>(null);
  final isOfflineMode = true.obs;
  final searchController = TextEditingController();

  // ── State Keranjang (Cart) ────────────────────────────────────────────────
  // Map dari FnbItemModel.id -> quantity
  final cart = <String, int>{}.obs;
  final itemNotes = <String, String>{}.obs;

  // ── State Checkout & Pesanan ──────────────────────────────────────────────
  final availableCinemas = <CinemaModel>[].obs;
  final selectedCinema = Rx<CinemaModel?>(null);
  final pickupMethod = 'counter'.obs; // 'counter' atau 'delivery'
  final studioNumber = ''.obs;
  final seatNumber = ''.obs;
  final selectedPaymentMethod = 'QRIS'.obs;
  final isSubmittingOrder = false.obs;

  // Riwayat pesanan
  final userOrders = <FnbOrderModel>[].obs;
  final isLoadingOrders = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFnbCatalog();
    loadActiveCart();
    loadCinemas();
    fetchUserOrders();
  }

  // ── Fetch & Filter ────────────────────────────────────────────────────────

  Future<void> fetchFnbCatalog({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      final result = await _service.getFnbItems(forceRefresh: forceRefresh);
      items.assignAll(result);
      lastCacheTime.value = await _service.getLastCacheTime();
      applyFilter();
    } catch (e) {
      debugPrint('[FnbController] Error fetching catalog: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    applyFilter();
  }

  int getCategoryCount(String category) {
    if (category == 'Semua') return items.length;
    final cat = category.toLowerCase();
    return items.where((it) {
      if (cat == 'snack') return it.category == 'snack';
      if (cat == 'minuman' || cat == 'drink') return it.category == 'drink';
      if (cat == 'combo') return it.category == 'combo';
      if (cat == 'makanan' || cat == 'food') return it.category == 'food';
      return it.category == cat;
    }).length;
  }

  Future<void> loadCinemas() async {
    try {
      final result = await _cinemaService.getAllCinemas();
      final list = result.cinemas;
      availableCinemas.assignAll(list);
      if (list.isNotEmpty && selectedCinema.value == null) {
        selectedCinema.value = list.first;
      }
    } catch (e) {
      debugPrint('[FnbController] Error loading cinemas: $e');
    }
  }

  void setCategory(String category) {
    selectedCategory.value = category;
    applyFilter();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    applyFilter();
  }

  void applyFilter() {
    var result = List<FnbItemModel>.from(items);

    // Filter kategori
    if (selectedCategory.value != 'Semua') {
      final cat = selectedCategory.value.toLowerCase();
      result = result.where((it) {
        if (cat == 'snack') return it.category == 'snack';
        if (cat == 'minuman' || cat == 'drink') return it.category == 'drink';
        if (cat == 'combo') return it.category == 'combo';
        if (cat == 'makanan' || cat == 'food') return it.category == 'food';
        return it.category == cat;
      }).toList();
    }

    // Filter pencarian
    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.trim().toLowerCase();
      result = result.where((it) {
        return it.name.toLowerCase().contains(q) ||
            it.description.toLowerCase().contains(q);
      }).toList();
    }

    filteredItems.assignAll(result);
  }

  // ── Cart Operations (PB-027) ──────────────────────────────────────────────

  Future<void> loadActiveCart() async {
    try {
      final savedCart = await _service.loadActiveCart();
      final savedNotes = await _service.loadActiveCartNotes();
      if (savedCart.isNotEmpty) {
        cart.assignAll(savedCart);
      }
      if (savedNotes.isNotEmpty) {
        itemNotes.assignAll(savedNotes);
      }
    } catch (e) {
      debugPrint('[FnbController] Error loading active cart from Hive: $e');
    }
  }

  void _persistCart() {
    _service.saveActiveCart(cart, itemNotes);
  }

  void addToCart(FnbItemModel item) {
    final current = cart[item.id] ?? 0;
    cart[item.id] = current + 1;
    cart.refresh();
    _persistCart();
  }

  void removeFromCart(FnbItemModel item) {
    final current = cart[item.id] ?? 0;
    if (current <= 1) {
      cart.remove(item.id);
      itemNotes.remove(item.id);
    } else {
      cart[item.id] = current - 1;
    }
    cart.refresh();
    _persistCart();
  }

  void setItemQuantity(FnbItemModel item, int quantity) {
    if (quantity <= 0) {
      cart.remove(item.id);
      itemNotes.remove(item.id);
    } else {
      cart[item.id] = quantity;
    }
    cart.refresh();
    _persistCart();
  }

  int getItemQuantity(String itemId) => cart[itemId] ?? 0;

  void setItemNote(String itemId, String note) {
    if (note.trim().isEmpty) {
      itemNotes.remove(itemId);
    } else {
      itemNotes[itemId] = note.trim();
    }
    _persistCart();
  }

  String getItemNote(String itemId) => itemNotes[itemId] ?? '';

  void clearCart() {
    cart.clear();
    itemNotes.clear();
    _service.clearActiveCart();
  }

  int get totalCartItems => cart.values.fold(0, (sum, q) => sum + q);

  int get subtotal {
    int total = 0;
    for (final entry in cart.entries) {
      final item = items.firstWhereOrNull((it) => it.id == entry.key);
      if (item != null) {
        total += item.price * entry.value;
      }
    }
    return total;
  }

  int get serviceFee => cart.isNotEmpty ? 2000 : 0;

  int get grandTotal => subtotal + serviceFee;

  String get formattedSubtotal => _formatRupiah(subtotal);
  String get formattedServiceFee => _formatRupiah(serviceFee);
  String get formattedGrandTotal => _formatRupiah(grandTotal);

  /// Daftar item terstruktur untuk keranjang bottom sheet & checkout
  List<Map<String, dynamic>> get cartItemsDetailed {
    final result = <Map<String, dynamic>>[];
    for (final entry in cart.entries) {
      final item = items.firstWhereOrNull((it) => it.id == entry.key);
      if (item != null) {
        result.add({
          'item': item,
          'quantity': entry.value,
          'subtotal': item.price * entry.value,
          'formattedSubtotal': _formatRupiah(item.price * entry.value),
          'note': itemNotes[item.id] ?? '',
        });
      }
    }
    return result;
  }

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  // ── Checkout & Pemesanan (PB-028, PB-029) ─────────────────────────────────

  /// Cek tiket aktif untuk pre-fill pengantaran ke studio & kursi
  void autoDetectActiveTicket() {
    try {
      if (Get.isRegistered<TicketsController>()) {
        final ticketCtrl = Get.find<TicketsController>();
        if (ticketCtrl.activeTickets.isNotEmpty) {
          final latestTicket = ticketCtrl.activeTickets.first;
          studioNumber.value = latestTicket.hallName;
          if (latestTicket.seats.isNotEmpty) {
            seatNumber.value = latestTicket.seats.join(', ');
          }
          // Cocokkan bioskop jika ada
          final matchingCinema = availableCinemas.firstWhereOrNull(
            (c) =>
                c.name.toLowerCase() == latestTicket.cinemaName.toLowerCase(),
          );
          if (matchingCinema != null) {
            selectedCinema.value = matchingCinema;
          }
        }
      }
    } catch (e) {
      debugPrint('[FnbController] Error auto-detecting ticket: $e');
    }
  }

  Future<FnbOrderModel?> submitOrder() async {
    if (cart.isEmpty) {
      Get.snackbar(
          'Keranjang Kosong', 'Silakan pilih makanan/minuman terlebih dahulu.');
      return null;
    }

    if (selectedCinema.value == null) {
      Get.snackbar('Pilih Bioskop', 'Pilih lokasi bioskop tempat pemesanan.');
      return null;
    }

    isSubmittingOrder.value = true;
    try {
      final List<FnbOrderItemModel> orderItems = [];
      for (final entry in cart.entries) {
        final item = items.firstWhereOrNull((it) => it.id == entry.key);
        if (item != null) {
          orderItems.add(FnbOrderItemModel(
            fnbItemId: item.id,
            name: item.name,
            price: item.price,
            quantity: entry.value,
            subtotal: item.price * entry.value,
            note: itemNotes[item.id],
          ));
        }
      }

      String userId = 'usr-anon';
      if (Get.isRegistered<AuthController>()) {
        userId =
            Get.find<AuthController>().currentUser.value?.id ?? 'usr-guest';
      }

      final newOrder = await _service.createOrder(
        userId: userId,
        cinemaId: selectedCinema.value!.id,
        cinemaName: selectedCinema.value!.name,
        items: orderItems,
        pickupMethod: pickupMethod.value,
        studioNumber:
            pickupMethod.value == 'delivery' ? studioNumber.value : null,
        seatNumber: pickupMethod.value == 'delivery' ? seatNumber.value : null,
        paymentMethod: selectedPaymentMethod.value,
      );

      // Reset keranjang
      clearCart();

      // Tambahkan ke riwayat pesanan
      userOrders.insert(0, newOrder);

      return newOrder;
    } catch (e) {
      debugPrint('[FnbController] Error submitting order: $e');
      Get.snackbar(
          'Pesanan Gagal', 'Terjadi kesalahan saat memproses pesanan.');
      return null;
    } finally {
      isSubmittingOrder.value = false;
    }
  }

  // ── Pelacakan & Riwayat Pesanan (PB-030) ───────────────────────────────────

  Future<void> fetchUserOrders() async {
    isLoadingOrders.value = true;
    try {
      String? userId;
      if (Get.isRegistered<AuthController>()) {
        userId = Get.find<AuthController>().currentUser.value?.id;
      }
      final orders = await _service.getUserOrders(userId: userId);
      userOrders.assignAll(orders);
    } catch (e) {
      debugPrint('[FnbController] Error fetching user orders: $e');
    } finally {
      isLoadingOrders.value = false;
    }
  }

  /// Simulasi tombol petugas untuk mengubah status pesanan (PB-030)
  Future<void> advanceOrderStatus(String orderId) async {
    final order = userOrders.firstWhereOrNull((o) => o.id == orderId);
    if (order == null) return;

    String nextStatus;
    if (order.status == 'processing') {
      nextStatus = 'ready';
    } else if (order.status == 'ready') {
      nextStatus = 'completed';
    } else {
      nextStatus = 'processing';
    }

    final updated = await _service.updateOrderStatus(orderId, nextStatus);
    if (updated != null) {
      final index = userOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        userOrders[index] = updated;
        userOrders.refresh();
      }
      Get.snackbar(
        'Status Diperbarui',
        'Pesanan ${updated.pickupCode} kini berstatus: ${updated.statusLabel}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
