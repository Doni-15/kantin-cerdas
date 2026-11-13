import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/utils/wib_date_formatter.dart';

void main() {
  group('formatWib', () {
    test('menggeser UTC ke WIB (UTC+7) dan memberi akhiran WIB', () {
      expect(formatWib(DateTime.utc(2026, 3, 5, 3, 4)), '05/03/2026 10:04 WIB');
    });

    test('melewati tengah malam dengan benar, termasuk pergantian tanggal', () {
      expect(
        formatWib(DateTime.utc(2026, 12, 31, 17, 30)),
        '01/01/2027 00:30 WIB',
      );
    });

    test('hasilnya sama untuk waktu lokal dan UTC pada instan yang sama', () {
      final utc = DateTime.utc(2026, 6, 15, 8, 45);

      expect(formatWib(utc.toLocal()), formatWib(utc));
    });
  });
}
