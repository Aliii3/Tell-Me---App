import 'package:flutter_test/flutter_test.dart';
import 'package:tell_me/providers/calendar_provider.dart';

void main() {
  group('dateKey()', () {
    test('formats DateTime as yyyy-MM-dd', () {
      expect(dateKey(DateTime(2026, 6, 14)), '2026-06-14');
      expect(dateKey(DateTime(2026, 1, 1)), '2026-01-01');
      expect(dateKey(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('pads single-digit month and day', () {
      expect(dateKey(DateTime(2026, 6, 4)), '2026-06-04');
      expect(dateKey(DateTime(2026, 1, 9)), '2026-01-09');
    });

    test('same day produces the same key regardless of time', () {
      final morning = DateTime(2026, 6, 14, 8, 0);
      final evening = DateTime(2026, 6, 14, 22, 30);
      expect(dateKey(morning), dateKey(evening));
    });

    test('different days produce different keys', () {
      expect(dateKey(DateTime(2026, 6, 14)),
          isNot(equals(dateKey(DateTime(2026, 6, 15)))));
    });
  });
}
