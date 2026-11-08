// test/fnb_order_cart_test.dart
// Unit tests untuk modul Pemesanan F&B (PB-026, PB-027, PB-028, PB-029, PB-030)

import 'package:flutter_test/flutter_test.dart';
import 'package:cinemate/models/fnb_item_model.dart';
import 'package:cinemate/models/fnb_order_model.dart';

void main() {
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

  group('FnbOrderModel & FnbOrderItemModel Tests (PB-027, PB-028, PB-029)', () {
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
}
