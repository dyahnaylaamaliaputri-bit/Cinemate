// test/fnb_order_cart_test.dart
// Unit tests untuk modul Pemesanan F&B (PB-026, PB-027, PB-028, PB-029, PB-030)
// Menguji FnbItemModel, FnbService (Hive Offline Cache), FnbController, dan FnbOrderModel

import 'dart:io';
import 'package:cinemate/controllers/fnb_controller.dart';
import 'package:cinemate/controllers/tickets_controller.dart';
import 'package:cinemate/models/fnb_item_model.dart';
import 'package:cinemate/models/fnb_order_model.dart';
import 'package:cinemate/models/ticket_model.dart';
import 'package:cinemate/services/fnb_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => tempDir.path,
    );
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('FnbItemModel Tests (PB-026)', () {
    test('seedItems should provide at least 10 items covering all categories',
        () {
      final items = FnbItemModel.seedItems;
      expect(items.length, greaterThanOrEqualTo(10));

      final categories = items.map((e) => e.category).toSet();
      expect(categories, containsAll(['snack', 'drink', 'combo', 'food']));
    });

    test(
        'FnbItemModel formattedPrice and categoryLabel should format correctly',
        () {
      const item = FnbItemModel(
        id: 'pop-caramel',
        name: 'Caramel Popcorn Large',
        description:
            'Popcorn renyah berbalut karamel manis gurih khas bioskop.',
        price: 48000,
        category: 'snack',
        imageUrl:
            'https://images.unsplash.com/photo-1578849278619-e73505e9610f',
      );

      expect(item.formattedPrice, equals('Rp 48.000'));
      expect(item.categoryLabel, equals('Snack & Camilan'));

      const drink = FnbItemModel(
        id: 'bev-cola',
        name: 'Coca-Cola Zero',
        description: 'Minuman soda dingin segar tanpa kalori.',
        price: 25000,
        category: 'drink',
        imageUrl: 'https://images.unsplash.com/photo-cola',
      );
      expect(drink.categoryLabel, equals('Minuman'));

      const combo = FnbItemModel(
        id: 'combo-1',
        name: 'Combo Duo Seru',
        description: 'Popcorn + 2 Minuman',
        price: 85000,
        category: 'combo',
        imageUrl: 'https://images.unsplash.com/photo-combo',
      );
      expect(combo.categoryLabel, equals('Paket Combo'));

      const food = FnbItemModel(
        id: 'food-hotdog',
        name: 'Classic Hot Dog',
        description: 'Sosis panggang dan mustard',
        price: 40000,
        category: 'food',
      );
      expect(food.categoryLabel, equals('Makanan Berat'));
    });

    test('FnbItemModel JSON serialization roundtrip', () {
      const item = FnbItemModel(
        id: 'combo-duo',
        name: 'Combo Duo Seru',
        description: '2 Popcorn Medium + 2 Minuman Soda 500ml',
        price: 85000,
        category: 'combo',
        imageUrl: 'https://images.unsplash.com/combo.jpg',
        isAvailable: true,
      );

      final json = item.toJson();
      final fromJson = FnbItemModel.fromJson(json);

      expect(fromJson.id, equals(item.id));
      expect(fromJson.name, equals(item.name));
      expect(fromJson.price, equals(item.price));
      expect(fromJson.category, equals(item.category));
      expect(fromJson.isAvailable, isTrue);
    });
  });

  group('FnbService Hive Offline Cache Tests (PB-026 Tanpa Supabase)', () {
    test(
        'getFnbItems should populate Hive box fnb_cache without requiring Supabase',
        () async {
      final service = FnbService();
      await service.clearCache();

      // Panggilan pertama: Harus menginisialisasi dari seed dan menyimpan ke Hive
      final items = await service.getFnbItems();
      expect(items.length, greaterThanOrEqualTo(10));

      final lastTime = await service.getLastCacheTime();
      expect(lastTime, isNotNull);

      // Verifikasi tersimpan di box Hive
      final box = Hive.box(FnbService.boxFnbCache);
      expect(box.containsKey('items'), isTrue);
      final cachedRaw = box.get('items') as List;
      expect(cachedRaw.length, equals(items.length));

      // Panggilan kedua: Membaca langsung dari cache Hive
      final cachedItems = await service.getFnbItems(forceRefresh: false);
      expect(cachedItems.length, equals(items.length));
      expect(cachedItems.first.name, equals(items.first.name));
    });
  });

  group('FnbController Filtering, Search & Count Tests (PB-026)', () {
    test('FnbController should filter by category and count accurately',
        () async {
      final controller = FnbController();
      await controller.fetchFnbCatalog();

      expect(controller.items.isNotEmpty, isTrue);
      expect(controller.getCategoryCount('Semua'),
          equals(controller.items.length));
      expect(controller.getCategoryCount('Snack'), greaterThan(0));
      expect(controller.getCategoryCount('Drink'), greaterThan(0));

      // Filter kategori Snack
      controller.setCategory('Snack');
      for (final it in controller.filteredItems) {
        expect(it.category, equals('snack'));
      }

      // Filter pencarian
      controller.setSearchQuery('popcorn');
      for (final it in controller.filteredItems) {
        expect(
            it.name.toLowerCase().contains('popcorn') ||
                it.description.toLowerCase().contains('popcorn'),
            isTrue);
      }

      // Reset / Clear pencarian
      controller.clearSearch();
      expect(controller.searchQuery.value, isEmpty);
    });

    test('FnbController Cart addition and removal operations (PB-027)', () {
      final controller = FnbController();
      final item = FnbItemModel.seedItems.first;

      expect(controller.cart.isEmpty, isTrue);
      controller.addToCart(item);
      expect(controller.getItemQuantity(item.id), equals(1));
      expect(controller.totalCartItems, equals(1));

      controller.addToCart(item);
      expect(controller.getItemQuantity(item.id), equals(2));
      expect(controller.totalCartItems, equals(2));

      controller.removeFromCart(item);
      expect(controller.getItemQuantity(item.id), equals(1));

      controller.removeFromCart(item);
      expect(controller.getItemQuantity(item.id), equals(0));
      expect(controller.cart.isEmpty, isTrue);
    });

    test(
        'FnbController Cart calculations subtotal, fee, grandTotal, and detailed list (PB-027)',
        () async {
      final controller = FnbController();
      await controller.fetchFnbCatalog();
      controller.clearCart();

      final item1 = controller.items[0]; // misal Popcorn Regular: 35.000
      final item2 = controller.items[1]; // misal Popcorn Large: 50.000

      controller.addToCart(item1);
      controller.addToCart(item1); // 2 x 35.000 = 70.000
      controller.addToCart(item2); // 1 x 50.000 = 50.000

      expect(controller.totalCartItems, equals(3));
      final expectedSubtotal = (item1.price * 2) + (item2.price * 1);
      expect(controller.subtotal, equals(expectedSubtotal));
      expect(controller.serviceFee, equals(2000));
      expect(controller.grandTotal, equals(expectedSubtotal + 2000));

      expect(controller.formattedSubtotal, contains('Rp '));
      expect(controller.formattedServiceFee, equals('Rp 2.000'));
      expect(controller.formattedGrandTotal, contains('Rp '));

      // Verifikasi cartItemsDetailed
      final detailed = controller.cartItemsDetailed;
      expect(detailed.length, equals(2));
      expect(detailed.first['quantity'], equals(2));
    });

    test('FnbController special instructions & notes per item (PB-027)', () {
      final controller = FnbController();
      final item = FnbItemModel.seedItems.first;

      controller.addToCart(item);
      expect(controller.getItemNote(item.id), isEmpty);

      controller.setItemNote(item.id, 'Ekstra bumbu gurih mentega');
      expect(
          controller.getItemNote(item.id), equals('Ekstra bumbu gurih mentega'));

      // Hapus catatan dengan string kosong
      controller.setItemNote(item.id, '');
      expect(controller.getItemNote(item.id), isEmpty);

      // Isi catatan lagi dan kosongkan keranjang
      controller.setItemNote(item.id, 'Tanpa es');
      controller.clearCart();
      expect(controller.cart.isEmpty, isTrue);
      expect(controller.getItemNote(item.id), isEmpty);
    });

    test('FnbService active cart persistence in Hive local storage (PB-027)',
        () async {
      final service = FnbService();
      await service.clearActiveCart();

      final initialCart = await service.loadActiveCart();
      expect(initialCart.isEmpty, isTrue);

      final dummyCart = {'fnb-popcorn-reg': 2, 'fnb-coke-reg': 3};
      final dummyNotes = {'fnb-coke-reg': 'Kurangi es batu'};

      await service.saveActiveCart(dummyCart, dummyNotes);

      final loadedCart = await service.loadActiveCart();
      final loadedNotes = await service.loadActiveCartNotes();

      expect(loadedCart, equals(dummyCart));
      expect(loadedNotes, equals(dummyNotes));

      await service.clearActiveCart();
      final clearedCart = await service.loadActiveCart();
      expect(clearedCart.isEmpty, isTrue);
    });
  });

  group('FnbOrderModel & FnbOrderItemModel Tests (PB-027, PB-028, PB-029, PB-030)',
      () {
    test(
        'FnbOrderItemModel should calculate total correctly and serialize properly',
        () {
      const orderItem = FnbOrderItemModel(
        fnbItemId: 'pop-caramel',
        name: 'Caramel Popcorn Large',
        price: 48000,
        quantity: 2,
        subtotal: 96000,
        note: 'Minta karamel ekstra',
      );

      expect(orderItem.subtotal, equals(96000));
      expect(orderItem.formattedSubtotal, equals('Rp 96.000'));

      final json = orderItem.toJson();
      final deserialized = FnbOrderItemModel.fromJson(json);
      expect(deserialized.name, equals('Caramel Popcorn Large'));
      expect(deserialized.quantity, equals(2));
      expect(deserialized.note, equals('Minta karamel ekstra'));
    });

    test(
        'FnbOrderModel pickupCode and qrPayload should conform to standards (PB-029, PB-030)',
        () {
      const items = [
        FnbOrderItemModel(
          fnbItemId: 'bev-cola',
          name: 'Coca-Cola Zero',
          price: 25000,
          quantity: 2,
          subtotal: 50000,
        ),
      ];

      final order = FnbOrderModel(
        id: 'fnb-ord-001',
        userId: 'user-nayla',
        cinemaId: 'cin-01',
        cinemaName: 'Cinemate Plaza',
        pickupCode: 'FNB-78219',
        status: 'ready',
        pickupMethod: 'counter',
        items: items,
        subtotal: 50000,
        serviceFee: 2000,
        totalPrice: 52000,
        paymentMethod: 'GoPay',
        createdAt: DateTime(2026, 11, 8, 14, 30),
      );

      // Verifikasi format kode pickup 5 digit
      expect(order.pickupCode, matches(r'^FNB-\d{5}$'));
      // Verifikasi status label
      expect(order.statusLabel, contains('Siap Diambil'));
      expect(order.pickupMethodLabel, contains('Ambil di Counter'));
      // Verifikasi QR payload
      expect(order.qrPayload,
          equals('CINEMATE_FNB:FNB-78219:fnb-ord-001:cin-01:ready'));
      // Verifikasi total
      expect(order.formattedTotalPrice, equals('Rp 52.000'));
    });

    test(
        'FnbOrderModel Delivery to Studio & Seat metadata serialization (PB-028)',
        () {
      final order = FnbOrderModel(
        id: 'fnb-ord-002',
        userId: 'user-nayla',
        cinemaId: 'cin-01',
        cinemaName: 'Cinemate Plaza',
        pickupCode: 'FNB-19283',
        status: 'processing',
        pickupMethod: 'delivery',
        studioNumber: '1',
        seatNumber: 'D8',
        items: const [],
        subtotal: 65000,
        serviceFee: 2000,
        totalPrice: 67000,
        paymentMethod: 'QRIS',
        createdAt: DateTime.now(),
      );

      expect(order.pickupMethodLabel, equals('Antar ke Studio 1 (Kursi D8)'));
      expect(order.statusLabel, contains('Sedang Disiapkan'));

      final json = order.toJson();
      final copy = FnbOrderModel.fromJson(json);

      expect(copy.pickupMethod, equals('delivery'));
      expect(copy.studioNumber, equals('1'));
      expect(copy.seatNumber, equals('D8'));
    });
  });

  group(
      'PB-028: Cinema Selection, Pickup Methods & Active Ticket Auto-Detection (Tanpa Supabase)',
      () {
    test('Cinema selection and local fallback cinemas without Supabase',
        () async {
      final controller = FnbController();
      await controller.loadCinemas();

      expect(controller.availableCinemas.isNotEmpty, isTrue);
      expect(controller.selectedCinema.value, isNotNull);

      // Verifikasi bioskop default
      expect(
          controller.selectedCinema.value?.name, contains('Cinemate Plaza'));

      // Switch cinema
      if (controller.availableCinemas.length > 1) {
        final secondCinema = controller.availableCinemas[1];
        controller.selectedCinema.value = secondCinema;
        expect(controller.selectedCinema.value, equals(secondCinema));
      }
    });

    test(
        'Auto-detection of active tickets pre-fills Studio, Seats, and Cinema',
        () async {
      Get.testMode = true;
      final ticketCtrl = Get.put(TicketsController());
      final dummyTicket = TicketModel(
        id: 't-test-01',
        bookingCode: 'CNM-77112',
        userId: 'usr-test',
        showtimeId: 'st-01',
        movieId: 550,
        movieTitle: 'Fight Club',
        cinemaId: 'd956c35c-2486-4b51-93f1-effe30152db1',
        cinemaName: 'Metro Cinema Senayan',
        cinemaAddress: 'Jl. Asia Afrika No. 8, Jakarta Selatan',
        hallName: 'Studio 3',
        experience: 'Regular 2D',
        showDate: '2026-11-12',
        showTime: '20:15',
        seats: ['F7', 'F8'],
        totalPrice: 110000,
        qrData: 'CNM-77112',
        createdAt: DateTime.now(),
      );
      ticketCtrl.activeTickets.assignAll([dummyTicket]);

      final fnbCtrl = FnbController();
      await fnbCtrl.loadCinemas();
      // Sebelum auto-detect, bioskop default adalah Cinemate Plaza
      expect(fnbCtrl.selectedCinema.value?.name, equals('Cinemate Plaza'));

      await fnbCtrl.autoDetectActiveTicket();

      expect(fnbCtrl.hasActiveTicketDetected.value, isTrue);
      expect(fnbCtrl.detectedActiveTicket.value, equals(dummyTicket));
      expect(fnbCtrl.studioNumber.value, equals('Studio 3'));
      expect(fnbCtrl.seatNumber.value, equals('F7, F8'));
      // Setelah auto-detect, bioskop otomatis cocok dengan tiket aktif
      expect(fnbCtrl.selectedCinema.value?.name,
          equals('Metro Cinema Senayan'));

      Get.delete<TicketsController>();
    });

    test('submitOrder validation: delivery requires studio and seat number',
        () async {
      Get.testMode = true;
      final fnbCtrl = FnbController();
      await fnbCtrl.fetchFnbCatalog();
      fnbCtrl.clearCart();

      // Empty cart validation
      var order = await fnbCtrl.submitOrder();
      expect(order, isNull);

      // Add item to cart
      fnbCtrl.addToCart(fnbCtrl.items.first);
      await fnbCtrl.loadCinemas();

      // Set delivery pickup method without studio and seat
      fnbCtrl.pickupMethod.value = 'delivery';
      fnbCtrl.studioNumber.value = '';
      fnbCtrl.seatNumber.value = '';

      order = await fnbCtrl.submitOrder();
      expect(order, isNull,
          reason: 'Harus ditolak jika studio & kursi kosong saat delivery');

      // Fill studio only, missing seat
      fnbCtrl.studioNumber.value = 'Studio 1';
      fnbCtrl.seatNumber.value = '';
      order = await fnbCtrl.submitOrder();
      expect(order, isNull);

      // Fill both studio and seat
      fnbCtrl.studioNumber.value = 'Studio 1';
      fnbCtrl.seatNumber.value = 'B4';
      order = await fnbCtrl.submitOrder();
      expect(order, isNotNull);
      expect(order!.pickupMethod, equals('delivery'));
      expect(order.studioNumber, equals('Studio 1'));
      expect(order.seatNumber, equals('B4'));
      expect(order.items.length, equals(1));
    });

    test('submitOrder counter pickup method succeeds without studio or seat',
        () async {
      Get.testMode = true;
      final fnbCtrl = FnbController();
      await fnbCtrl.fetchFnbCatalog();
      fnbCtrl.clearCart();
      fnbCtrl.addToCart(fnbCtrl.items.first);
      await fnbCtrl.loadCinemas();

      fnbCtrl.pickupMethod.value = 'counter';
      fnbCtrl.studioNumber.value = '';
      fnbCtrl.seatNumber.value = '';

      final order = await fnbCtrl.submitOrder();
      expect(order, isNotNull);
      expect(order!.pickupMethod, equals('counter'));
      expect(order.pickupCode, startsWith('FNB-'));
    });

    test(
        'PB-033 (FR-036): Independent F&B order without ticket succeeds with processing status and pickup code',
        () async {
      Get.testMode = true;
      final fnbCtrl = FnbController();
      await fnbCtrl.fetchFnbCatalog();
      fnbCtrl.clearCart();

      // Pilih 2 item makanan
      fnbCtrl.addToCart(fnbCtrl.items[0]);
      fnbCtrl.addToCart(fnbCtrl.items[1]);
      await fnbCtrl.loadCinemas();

      // Pilih metode ambil di counter mandiri tanpa tiket aktif
      fnbCtrl.pickupMethod.value = 'counter';
      expect(fnbCtrl.hasActiveTicketDetected.value, isFalse);

      final order = await fnbCtrl.submitOrder();
      expect(order, isNotNull);
      expect(order!.status, equals('processing'));
      expect(order.statusLabel, contains('Sedang Disiapkan'));
      expect(order.pickupCode, matches(r'^FNB-\d{5}$'));
      expect(order.items.length, equals(2));

      // Verifikasi tersimpan di userOrders
      expect(fnbCtrl.userOrders.any((o) => o.id == order.id), isTrue);

      // Verifikasi keranjang tereset setelah pemesanan
      expect(fnbCtrl.cart.isEmpty, isTrue);
    });
  });
}
