// test/timezone_format_test.dart
// Unit test untuk penyesuaian zona waktu jam tayang film (PB-049, PB-050)

import 'package:cinemate/models/showtime_model.dart';
import 'package:cinemate/utils/timezone_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PB-049: TimezoneHelper Supported Zones & Offsets Tests', () {
    test('Supported zones should include WIB, WITA, WIT, and London', () {
      final zones = TimezoneHelper.supportedZones;
      expect(zones.containsKey('WIB'), isTrue);
      expect(zones.containsKey('WITA'), isTrue);
      expect(zones.containsKey('WIT'), isTrue);
      expect(zones.containsKey('London'), isTrue);

      expect(zones['WIB']!.offsetHours, equals(7));
      expect(zones['WITA']!.offsetHours, equals(8));
      expect(zones['WIT']!.offsetHours, equals(9));
      expect(zones['London']!.offsetHours, equals(0));
    });

    test('normalizeCode should handle standard variations and full names', () {
      expect(TimezoneHelper.normalizeCode('WIB'), equals('WIB'));
      expect(TimezoneHelper.normalizeCode('Asia/Jakarta'), equals('WIB'));
      expect(TimezoneHelper.normalizeCode('Asia/Makassar'), equals('WITA'));
      expect(TimezoneHelper.normalizeCode('Asia/Jayapura'), equals('WIT'));
      expect(TimezoneHelper.normalizeCode('Europe/London'), equals('London'));
      expect(TimezoneHelper.normalizeCode('GMT'), equals('London'));
      expect(TimezoneHelper.normalizeCode(null), equals('WIB'));
    });
  });

  group('PB-049: Time Conversion Calculation Tests', () {
    test(
        'convertTimeString: 19:00 WIB to WITA and WIT should advance 1 and 2 hours',
        () {
      const wibTime = '19:00';

      // WIB (UTC+7) -> WITA (UTC+8) = +1 jam -> 20:00 WITA
      final wita = TimezoneHelper.convertTimeString(
        wibTime,
        sourceZone: 'WIB',
        targetZone: 'WITA',
      );
      expect(wita, equals('20:00 WITA'));

      // WIB (UTC+7) -> WIT (UTC+9) = +2 jam -> 21:00 WIT
      final wit = TimezoneHelper.convertTimeString(
        wibTime,
        sourceZone: 'WIB',
        targetZone: 'WIT',
      );
      expect(wit, equals('21:00 WIT'));
    });

    test('convertTimeString: 19:00 WIB to London should subtract 7 hours', () {
      const wibTime = '19:00';

      // 19:00 - 7 jam = 12:00 GMT
      final london = TimezoneHelper.convertTimeString(
        wibTime,
        sourceZone: 'WIB',
        targetZone: 'London',
      );
      expect(london, equals('12:00 GMT'));
    });

    test(
        'convertTimeString: Midnight rollover wrap around should work smoothly',
        () {
      // 23:30 WIB -> WIT (23:30 + 2 = 01:30 WIT esok hari)
      final midnightRoll = TimezoneHelper.convertTimeString(
        '23:30',
        sourceZone: 'WIB',
        targetZone: 'WIT',
      );
      expect(midnightRoll, equals('01:30 WIT'));

      // 03:00 WIB -> London (03:00 - 7 = 20:00 GMT hari sebelumnya)
      final earlyMorningRoll = TimezoneHelper.convertTimeString(
        '03:00',
        sourceZone: 'WIB',
        targetZone: 'London',
      );
      expect(earlyMorningRoll, equals('20:00 GMT'));
    });

    test('ShowtimeModel formattedTimeWithZone integration', () {
      const showtime = ShowtimeModel(
        id: 'st-tz-test',
        cinemaId: 'cin-1',
        movieId: 101,
        movieTitle: 'Interstellar',
        showDate: '2026-11-20',
        showTime: '15:45',
        hallName: 'IMAX 1',
      );

      expect(showtime.formattedTimeWithZone('WIB'), equals('15:45 WIB'));
      expect(showtime.formattedTimeWithZone('WITA'), equals('16:45 WITA'));
      expect(showtime.formattedTimeWithZone('WIT'), equals('17:45 WIT'));
      expect(showtime.formattedTimeWithZone('London'), equals('08:45 GMT'));
    });
  });
}
