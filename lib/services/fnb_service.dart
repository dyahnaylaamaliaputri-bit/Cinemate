// lib/services/fnb_service.dart
// Service untuk manajemen Makanan & Minuman (F&B), integrasi Supabase & Hive cache (PB-026, PB-028, PB-029, PB-030)

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/fnb_item_model.dart';
import '../models/fnb_order_model.dart';
import 'supabase_service.dart';

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

  /// Ambil katalog F&B dengan strategi Cache-First / Fallback (PB-026)
  Future<List<FnbItemModel>> getFnbItems({bool forceRefresh = false}) async {
    final box = await _getFnbBox();

    // 1. Cek cache Hive jika tidak force refresh
    if (!forceRefresh && box.containsKey('items')) {
      try {
        final cachedRaw = box.get('items');
        if (cachedRaw is List && cachedRaw.isNotEmpty) {
          final items = cachedRaw.map((e) {
            return FnbItemModel.fromJson(Map<String, dynamic>.from(e as Map));
          }).toList();
          if (items.isNotEmpty) return items;
        }
      } catch (e) {
        debugPrint('[FnbService] Error reading Hive cache: $e');
      }
    }

    // 2. Coba ambil dari Supabase
    try {
      final client = SupabaseService().client;
      final response = await client
          .from('fnb_items')
          .select()
          .order('category', ascending: true);

      if (response.isNotEmpty) {
        final items = (response as List)
            .map((e) =>
                FnbItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        // Simpan ke Hive cache
        await box.put('items', items.map((i) => i.toJson()).toList());
        await box.put(keyFnbTimestamp, DateTime.now().toIso8601String());
        return items;
      }
    } catch (e) {
      debugPrint(
          '[FnbService] Supabase fetch error (fallback to seed/cache): $e');
    }

    // 3. Fallback: gunakan seed data bawaan
    final seed = FnbItemModel.seedItems;
    await box.put('items', seed.map((i) => i.toJson()).toList());
    return seed;
  }

  /// Generate kode pengambilan F&B unik (format: FNB-XXXXX)
  String generatePickupCode() {
    final rnd = Random();
    final number = 10000 + rnd.nextInt(90000);
    return 'FNB-$number';
  }

  /// Membuat pesanan F&B baru (PB-029)
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

    // 1. Simpan ke Hive lokal terlebih dahulu (Offline-first & reliable)
    await ordersBox.put(newOrder.id, newOrder.toJson());

    // 2. Upayakan sinkronisasi ke Supabase
    try {
      final client = SupabaseService().client;
      await client.from('fnb_orders').insert({
        'id': newOrder.id,
        'user_id': userId,
        'cinema_id': cinemaId,
        'pickup_code': pickupCode,
        'status': 'processing',
        'total_price': total,
        'created_at': newOrder.createdAt.toIso8601String(),
      });

      // Insert detail item
      for (final it in items) {
        await client.from('fnb_order_items').insert({
          'order_id': newOrder.id,
          'fnb_item_id': it.fnbItemId,
          'quantity': it.quantity,
          'note': it.note,
          'subtotal': it.subtotal,
        });
      }
    } catch (e) {
      debugPrint(
          '[FnbService] Supabase insert order warning (saved to Hive): $e');
    }

    return newOrder;
  }

  /// Ambil riwayat pesanan F&B pengguna (PB-030)
  Future<List<FnbOrderModel>> getUserOrders({String? userId}) async {
    final ordersBox = await _getOrdersBox();

    // 1. Ambil dari Hive cache
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

    // Urutkan dari yang paling baru
    localOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Jika Hive ada data, kembalikan segera
    if (localOrders.isNotEmpty) {
      return localOrders;
    }

    // 2. Jika Hive kosong, coba tarik dari Supabase
    try {
      final client = SupabaseService().client;
      var query = client.from('fnb_orders').select('*, fnb_order_items(*)');
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }
      final response = await query.order('created_at', ascending: false);

      final List<FnbOrderModel> fetched = [];
      for (final r in response as List) {
        final order =
            FnbOrderModel.fromJson(Map<String, dynamic>.from(r as Map));
        fetched.add(order);
        await ordersBox.put(order.id, order.toJson());
      }
      return fetched;
    } catch (e) {
      debugPrint('[FnbService] Fetch orders from Supabase error: $e');
      return localOrders;
    }
  }

  /// Update status pesanan F&B (Simulasi Petugas: processing -> ready -> completed)
  Future<FnbOrderModel?> updateOrderStatus(
      String orderId, String newStatus) async {
    final ordersBox = await _getOrdersBox();
    final raw = ordersBox.get(orderId);
    if (raw == null) return null;

    final order = FnbOrderModel.fromJson(Map<String, dynamic>.from(raw as Map));
    final updated = order.copyWith(status: newStatus);

    await ordersBox.put(orderId, updated.toJson());

    try {
      final client = SupabaseService().client;
      await client
          .from('fnb_orders')
          .update({'status': newStatus}).eq('id', orderId);
    } catch (e) {
      debugPrint('[FnbService] Supabase status update warning: $e');
    }

    return updated;
  }
}
