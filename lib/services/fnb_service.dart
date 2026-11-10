// lib/services/fnb_service.dart
// Service untuk manajemen Makanan & Minuman (F&B) berbasis Hive Offline Cache (PB-026)
// Catatan: Dirancang 100% offline-first tanpa ketergantungan koneksi Supabase.

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/fnb_item_model.dart';
import '../models/fnb_order_model.dart';

class FnbService {
  FnbService._internal();
  static final FnbService _instance = FnbService._internal();
  factory FnbService() => _instance;

  static const String boxFnbCache = 'fnb_cache';
  static const String boxFnbOrders = 'fnb_orders_cache';
  static const String keyFnbTimestamp = 'fnb_last_fetched';

  /// Mendapatkan box Hive untuk katalog menu
  Future<Box> _getFnbBox() async {
    if (Hive.isBoxOpen(boxFnbCache)) {
      return Hive.box(boxFnbCache);
    }
    return await Hive.openBox(boxFnbCache);
  }

  /// Mendapatkan box Hive untuk riwayat pesanan F&B
  Future<Box> _getOrdersBox() async {
    if (Hive.isBoxOpen(boxFnbOrders)) {
      return Hive.box(boxFnbOrders);
    }
    return await Hive.openBox(boxFnbOrders);
  }

  /// Ambil katalog F&B dari Hive Local Storage (PB-026 Offline-First)
  /// Jika cache kosong atau forceRefresh = true, otomatis inisialisasi dari seed katalog
  Future<List<FnbItemModel>> getFnbItems({bool forceRefresh = false}) async {
    final box = await _getFnbBox();

    // 1. Cek cache Hive jika tidak diminta force refresh
    if (!forceRefresh && box.containsKey('items')) {
      try {
        final cachedRaw = box.get('items');
        if (cachedRaw is List && cachedRaw.isNotEmpty) {
          final items = cachedRaw.map((e) {
            return FnbItemModel.fromJson(Map<String, dynamic>.from(e as Map));
          }).toList();
          if (items.isNotEmpty) {
            debugPrint(
                '[FnbService] Berhasil memuat ${items.length} menu F&B dari Hive cache.');
            return items;
          }
        }
      } catch (e) {
        debugPrint('[FnbService] Gagal membaca Hive cache: $e');
      }
    }

    // 2. Inisialisasi / perbarui cache lokal Hive dari seed data bawaan
    final seed = FnbItemModel.seedItems;
    try {
      await box.put('items', seed.map((i) => i.toJson()).toList());
      await box.put(keyFnbTimestamp, DateTime.now().toIso8601String());
      debugPrint(
          '[FnbService] Hive cache F&B diinisialisasi dengan ${seed.length} menu.');
    } catch (e) {
      debugPrint('[FnbService] Error menyimpan seed ke Hive: $e');
    }

    return seed;
  }

  /// Waktu terakhir kali data katalog F&B diperbarui di Hive
  Future<DateTime?> getLastCacheTime() async {
    try {
      final box = await _getFnbBox();
      final raw = box.get(keyFnbTimestamp);
      if (raw is String) {
        return DateTime.tryParse(raw);
      }
    } catch (e) {
      debugPrint('[FnbService] Error membaca timestamp cache: $e');
    }
    return null;
  }

  /// Hapus cache katalog F&B (untuk simulasi/testing)
  Future<void> clearCache() async {
    final box = await _getFnbBox();
    await box.delete('items');
    await box.delete(keyFnbTimestamp);
  }

  /// Generate kode pengambilan F&B unik (format: FNB-XXXXX)
  String generatePickupCode() {
    final rnd = Random();
    final number = 10000 + rnd.nextInt(90000);
    return 'FNB-$number';
  }

  /// Membuat pesanan F&B baru (PB-029: Disimpan ke Hive lokal)
  Future<FnbOrderModel> createOrder({
    required String userId,
    required String cinemaId,
    required String cinemaName,
    required List<FnbOrderItemModel> items,
    required String pickupMethod,
    String? studioNumber,
    String? seatNumber,
    required String paymentMethod,
  }) async {
    final ordersBox = await _getOrdersBox();

    final subtotal = items.fold<int>(0, (sum, item) => sum + item.subtotal);
    const serviceFee = 2000;
    final total = subtotal + serviceFee;
    final pickupCode = generatePickupCode();
    final orderId = 'ORD-FNB-${DateTime.now().millisecondsSinceEpoch}';

    final newOrder = FnbOrderModel(
      id: orderId,
      userId: userId,
      cinemaId: cinemaId,
      cinemaName: cinemaName,
      pickupCode: pickupCode,
      status: 'processing',
      pickupMethod: pickupMethod,
      studioNumber: studioNumber,
      seatNumber: seatNumber,
      subtotal: subtotal,
      serviceFee: serviceFee,
      totalPrice: total,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      items: items,
    );

    // Simpan ke Hive box riwayat lokal
    await ordersBox.put(newOrder.id, newOrder.toJson());
    debugPrint(
        '[FnbService] Pesanan F&B ${newOrder.pickupCode} berhasil disimpan ke Hive lokal.');

    return newOrder;
  }

  /// Ambil riwayat pesanan F&B pengguna langsung dari Hive (PB-030)
  Future<List<FnbOrderModel>> getUserOrders({String? userId}) async {
    final ordersBox = await _getOrdersBox();

    final List<FnbOrderModel> localOrders = [];
    for (var key in ordersBox.keys) {
      try {
        final raw = ordersBox.get(key);
        if (raw is Map) {
          final order = FnbOrderModel.fromJson(Map<String, dynamic>.from(raw));
          if (userId == null ||
              order.userId == userId ||
              order.userId.isEmpty) {
            localOrders.add(order);
          }
        }
      } catch (e) {
        debugPrint('[FnbService] Parse order error: $e');
      }
    }

    // Urutkan dari yang terbaru
    localOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return localOrders;
  }

  /// Update status pesanan F&B di Hive lokal (Simulasi: processing -> ready -> completed)
  Future<FnbOrderModel?> updateOrderStatus(
      String orderId, String newStatus) async {
    final ordersBox = await _getOrdersBox();
    final raw = ordersBox.get(orderId);
    if (raw == null) return null;

    final order = FnbOrderModel.fromJson(Map<String, dynamic>.from(raw as Map));
    final updated = order.copyWith(status: newStatus);

    await ordersBox.put(orderId, updated.toJson());
    debugPrint(
        '[FnbService] Status pesanan $orderId diubah menjadi $newStatus di Hive.');

    return updated;
  }
}
