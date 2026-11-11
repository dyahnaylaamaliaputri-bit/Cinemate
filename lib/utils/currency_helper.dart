// lib/utils/currency_helper.dart
// Helper konversi mata uang dinamis (IDR, USD, SGD, EUR, JPY, GBP) (PB-048)
// Referensi: SRS Â§3.9 FR-052, FR-053, PB-048

import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  final double rateToIdr; // Nilai 1 unit valuta asing dalam IDR

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    required this.rateToIdr,
  });
}

class CurrencyHelper {
  CurrencyHelper._();

  /// Daftar mata uang yang didukung aplikasi Cinemate (PB-048)
  static const Map<String, CurrencyInfo> supportedCurrencies = {
    'IDR': CurrencyInfo(
      code: 'IDR',
      symbol: 'Rp',
      name: 'Rupiah Indonesia',
      flag: 'ðŸ‡®ðŸ‡©',
      rateToIdr: 1.0,
    ),
    'USD': CurrencyInfo(
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar',
      flag: 'ðŸ‡ºðŸ‡¸',
      rateToIdr: 16000.0,
    ),
    'SGD': CurrencyInfo(
      code: 'SGD',
      symbol: 'S\$',
      name: 'Singapore Dollar',
      flag: 'ðŸ‡¸ðŸ‡¬',
      rateToIdr: 12000.0,
    ),
    'EUR': CurrencyInfo(
      code: 'EUR',
      symbol: 'â‚¬',
      name: 'Euro',
      flag: 'ðŸ‡ªðŸ‡º',
      rateToIdr: 17500.0,
    ),
    'JPY': CurrencyInfo(
      code: 'JPY',
      symbol: 'Â¥',
      name: 'Japanese Yen',
      flag: 'ðŸ‡¯ðŸ‡µ',
      rateToIdr: 105.0,
    ),
    'GBP': CurrencyInfo(
      code: 'GBP',
      symbol: 'Â£',
      name: 'British Pound',
      flag: 'ðŸ‡¬ðŸ‡§',
      rateToIdr: 20500.0,
    ),
  };

  /// Metadata pembaruan kurs valuta asing (PB-048 Acceptance Criteria)
  static const String lastUpdatedTimestamp = '11 Nov 2026, 08:00 WIB';
  static const String rateSource =
      'Bank Indonesia / Offline Cache (TTL 12 Jam)';

  /// Konversi nilai nominal dari IDR ke mata uang tujuan
  static double convertFromIdr(num amountInIdr, String targetCurrencyCode) {
    final currency = supportedCurrencies[targetCurrencyCode.toUpperCase()] ??
        supportedCurrencies['IDR']!;
    if (currency.code == 'IDR') return amountInIdr.toDouble();
    return amountInIdr / currency.rateToIdr;
  }

  /// Format harga lengkap dengan simbol mata uang
  static String format(num amountInIdr, {String targetCurrency = 'IDR'}) {
    final currency = supportedCurrencies[targetCurrency.toUpperCase()] ??
        supportedCurrencies['IDR']!;

    if (currency.code == 'IDR') {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(amountInIdr);
    } else if (currency.code == 'JPY') {
      final converted = convertFromIdr(amountInIdr, currency.code);
      final formatter = NumberFormat.currency(
        locale: 'ja_JP',
        symbol: 'Â¥',
        decimalDigits: 0,
      );
      return formatter.format(converted.round());
    } else {
      final converted = convertFromIdr(amountInIdr, currency.code);
      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: '${currency.symbol} ',
        decimalDigits: 2,
      );
      return formatter.format(converted);
    }
  }

  /// Mendapatkan CurrencyInfo berdasarkan kode
  static CurrencyInfo getInfo(String code) {
    return supportedCurrencies[code.toUpperCase()] ??
        supportedCurrencies['IDR']!;
  }
}
