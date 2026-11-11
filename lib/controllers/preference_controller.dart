// lib/controllers/preference_controller.dart
// Controller untuk preferensi global aplikasi: Mata Uang & Zona Waktu (PB-048, PB-049, PB-050)
// Menyediakan state reaktif dan persistensi ke GetStorage.

import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../utils/currency_helper.dart';
import '../utils/timezone_helper.dart';

class PreferenceController extends GetxController {
  final StorageService _storage = StorageService();

  final selectedCurrency = 'IDR'.obs;
  final selectedTimezone = 'WIB'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }

  void _loadPreferences() {
    selectedCurrency.value = _storage.currencyPref;
    selectedTimezone.value =
        TimezoneHelper.normalizeCode(_storage.timezonePref);
  }

  /// Mengubah preferensi mata uang dan menyimpan ke local storage (PB-048, PB-050)
  void setCurrency(String code) {
    selectedCurrency.value = code.toUpperCase();
    _storage.currencyPref = code.toUpperCase();
  }

  /// Mengubah preferensi zona waktu dan menyimpan ke local storage (PB-049, PB-050)
  void setTimezone(String code) {
    final normalized = TimezoneHelper.normalizeCode(code);
    selectedTimezone.value = normalized;
    _storage.timezonePref = normalized;
  }

  /// Format harga instan sesuai mata uang yang aktif
  String formatPrice(num amountInIdr) {
    return CurrencyHelper.format(amountInIdr,
        targetCurrency: selectedCurrency.value);
  }

  /// Format jam tayang film sesuai zona waktu yang aktif
  String formatShowtime(String timeStr) {
    return TimezoneHelper.convertTimeString(timeStr,
        targetZone: selectedTimezone.value);
  }
}
