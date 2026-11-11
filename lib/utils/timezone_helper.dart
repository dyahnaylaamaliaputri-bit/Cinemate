// lib/utils/timezone_helper.dart
// Helper penyesuaian zona waktu jam tayang film (PB-049)
// Mendukung WIB (UTC+7), WITA (UTC+8), WIT (UTC+9), dan London (GMT/BST UTC+0/+1).
// Referensi: SRS Â§3.9 FR-054, PB-049

class TimezoneInfo {
  final String code;
  final String name;
  final String city;
  final int offsetHours; // Jam offset relatif terhadap UTC

  const TimezoneInfo({
    required this.code,
    required this.name,
    required this.city,
    required this.offsetHours,
  });
}

class TimezoneHelper {
  TimezoneHelper._();

  static const Map<String, TimezoneInfo> supportedZones = {
    'WIB': TimezoneInfo(
      code: 'WIB',
      name: 'Waktu Indonesia Barat (UTC+7)',
      city: 'Jakarta, Bandung, Medan',
      offsetHours: 7,
    ),
    'WITA': TimezoneInfo(
      code: 'WITA',
      name: 'Waktu Indonesia Tengah (UTC+8)',
      city: 'Bali, Makassar, Balikpapan',
      offsetHours: 8,
    ),
    'WIT': TimezoneInfo(
      code: 'WIT',
      name: 'Waktu Indonesia Timur (UTC+9)',
      city: 'Jayapura, Ambon',
      offsetHours: 9,
    ),
    'London': TimezoneInfo(
      code: 'London',
      name: 'London / GMT (UTC+0)',
      city: 'London, UK (GMT/BST)',
      offsetHours: 0,
    ),
  };

  /// Normalisasi kode zona waktu (misal: 'Asia/Jakarta' -> 'WIB')
  static String normalizeCode(String? raw) {
    if (raw == null) return 'WIB';
    final upper = raw.toUpperCase();
    if (upper.contains('JAKARTA') || upper == 'WIB') return 'WIB';
    if (upper.contains('MAKASSAR') || upper == 'WITA') return 'WITA';
    if (upper.contains('JAYAPURA') || upper == 'WIT') return 'WIT';
    if (upper.contains('LONDON') || upper == 'GMT' || upper == 'BST') {
      return 'London';
    }
    return 'WIB';
  }

  /// Menyesuaikan jam tayang berformat teks (misal: "19:00") dari WIB ke zona tujuan (PB-049)
  static String convertTimeString(
    String timeStr, {
    String sourceZone = 'WIB',
    String targetZone = 'WIB',
    bool includeZoneLabel = true,
  }) {
    final cleanTime = timeStr.trim();
    final parts = cleanTime.split(':');
    if (parts.length < 2) return timeStr;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1].split(' ')[0]);
    if (hour == null || minute == null) return timeStr;

    final src =
        supportedZones[normalizeCode(sourceZone)] ?? supportedZones['WIB']!;
    final tgt =
        supportedZones[normalizeCode(targetZone)] ?? supportedZones['WIB']!;

    final hourDiff = tgt.offsetHours - src.offsetHours;
    var adjustedHour = (hour + hourDiff) % 24;
    if (adjustedHour < 0) adjustedHour += 24;

    final hourStr = adjustedHour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');

    if (!includeZoneLabel) return '$hourStr:$minuteStr';
    final label = tgt.code == 'London' ? 'GMT' : tgt.code;
    return '$hourStr:$minuteStr $label';
  }

  /// Menyesuaikan DateTime dari WIB ke zona target
  static DateTime convertDateTime(
    DateTime dt, {
    String sourceZone = 'WIB',
    String targetZone = 'WIB',
  }) {
    final src =
        supportedZones[normalizeCode(sourceZone)] ?? supportedZones['WIB']!;
    final tgt =
        supportedZones[normalizeCode(targetZone)] ?? supportedZones['WIB']!;
    final hourDiff = tgt.offsetHours - src.offsetHours;
    return dt.add(Duration(hours: hourDiff));
  }

  /// Mendapatkan info zona waktu
  static TimezoneInfo getInfo(String code) {
    return supportedZones[normalizeCode(code)] ?? supportedZones['WIB']!;
  }
}
