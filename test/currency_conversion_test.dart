// test/currency_conversion_test.dart
// Unit test untuk konversi mata uang dinamis & preferensi valuta asing (PB-048, PB-050)

import 'package:cinemate/models/fnb_item_model.dart';
import 'package:cinemate/models/showtime_model.dart';
import 'package:cinemate/utils/currency_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PB-048: CurrencyHelper Supported Currencies & Rates Tests', () {
    test('Supported currencies should contain IDR, USD, SGD, EUR, JPY, and GBP',
        () {
      final supported = CurrencyHelper.supportedCurrencies;
      expect(supported.containsKey('IDR'), isTrue);
      expect(supported.containsKey('USD'), isTrue);
      expect(supported.containsKey('SGD'), isTrue);
      expect(supported.containsKey('EUR'), isTrue);
      expect(supported.containsKey('JPY'), isTrue);
      expect(supported.containsKey('GBP'), isTrue);

      expect(CurrencyHelper.getInfo('USD').symbol, equals('\$'));
      expect(CurrencyHelper.getInfo('EUR').symbol, equals('â‚¬'));
      expect(CurrencyHelper.getInfo('JPY').symbol, equals('Â¥'));
      expect(CurrencyHelper.getInfo('GBP').symbol, equals('Â£'));
      expect(CurrencyHelper.getInfo('SGD').symbol, equals('S\$'));
    });

    test('Metadata timestamp & source should be defined', () {
      expect(CurrencyHelper.lastUpdatedTimestamp, isNotEmpty);
      expect(CurrencyHelper.rateSource, contains('Offline Cache'));
    });

    test('Conversion from IDR to foreign currencies should compute accurately',
        () {
      const idrAmount = 160000; // Rp 160.000

      // 160.000 IDR / 16.000 = 10.0 USD
      final inUsd = CurrencyHelper.convertFromIdr(idrAmount, 'USD');
      expect(inUsd, closeTo(10.0, 0.01));

      // 160.000 IDR / 12.000 = ~13.33 SGD
      final inSgd = CurrencyHelper.convertFromIdr(idrAmount, 'SGD');
      expect(inSgd, closeTo(13.33, 0.05));

      // IDR to IDR remains unchanged
      final inIdr = CurrencyHelper.convertFromIdr(idrAmount, 'IDR');
      expect(inIdr, equals(160000.0));
    });

    test('format method should output correct currency symbols and locales',
        () {
      const price = 50000; // Rp 50.000

      final formattedIdr = CurrencyHelper.format(price, targetCurrency: 'IDR');
      expect(formattedIdr, contains('Rp'));
      expect(formattedIdr, contains('50.000'));

      final formattedUsd = CurrencyHelper.format(price, targetCurrency: 'USD');
      expect(formattedUsd, contains('\$'));
      expect(formattedUsd, contains('3.13')); // 50000 / 16000 = 3.125 -> 3.13

      final formattedJpy = CurrencyHelper.format(price, targetCurrency: 'JPY');
      expect(formattedJpy, contains('Â¥'));
    });
  });

  group('PB-048 Integration: ShowtimeModel & FnbItemModel Multi-Currency Tests',
      () {
    test('ShowtimeModel formattedPriceWithCurrency should format dynamically',
        () {
      const showtime = ShowtimeModel(
        id: 'st-test',
        cinemaId: 'cin-1',
        movieId: 101,
        movieTitle: 'Inception',
        showDate: '2026-11-20',
        showTime: '19:00',
        hallName: 'Studio 1',
        price: 50000,
      );

      expect(showtime.formattedPrice, contains('Rp 50.000'));
      expect(showtime.formattedPriceWithCurrency('IDR'), contains('Rp'));
      expect(showtime.formattedPriceWithCurrency('USD'), contains('\$'));
      expect(showtime.formattedPriceWithCurrency('EUR'), contains('â‚¬'));
    });

    test('FnbItemModel formattedPriceWithCurrency should format dynamically',
        () {
      const item = FnbItemModel(
        id: 'fnb-popcorn',
        name: 'Popcorn Caramel Large',
        description: 'Jagung manis mekar gurih',
        price: 35000,
        category: 'snack',
      );

      expect(item.formattedPrice, contains('Rp 35.000'));
      expect(item.formattedPriceWithCurrency('IDR'), contains('Rp'));
      expect(item.formattedPriceWithCurrency('USD'), contains('\$'));
      expect(item.formattedPriceWithCurrency('SGD'), contains('S\$'));
    });
  });
}
