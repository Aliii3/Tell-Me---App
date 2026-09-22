import 'package:flutter_test/flutter_test.dart';
import 'package:tell_me/utils/extensions.dart';

void main() {
  group('DateTimeX.dayName', () {
    test('returns correct 3-letter abbreviation for each weekday', () {
      expect(DateTime(2026, 6, 15).dayName, 'Mon'); // Monday
      expect(DateTime(2026, 6, 16).dayName, 'Tue');
      expect(DateTime(2026, 6, 17).dayName, 'Wed');
      expect(DateTime(2026, 6, 18).dayName, 'Thu');
      expect(DateTime(2026, 6, 19).dayName, 'Fri');
      expect(DateTime(2026, 6, 20).dayName, 'Sat');
      expect(DateTime(2026, 6, 21).dayName, 'Sun');
    });
  });

  group('DateTimeX.monthName', () {
    test('returns full month names', () {
      expect(DateTime(2026, 1, 1).monthName, 'January');
      expect(DateTime(2026, 6, 1).monthName, 'June');
      expect(DateTime(2026, 12, 1).monthName, 'December');
    });
  });

  group('DateTimeX.isSameDayAs', () {
    test('returns true for same calendar day regardless of time', () {
      final a = DateTime(2026, 6, 14, 9, 0);
      final b = DateTime(2026, 6, 14, 23, 59);
      expect(a.isSameDayAs(b), isTrue);
    });

    test('returns false for different days', () {
      final a = DateTime(2026, 6, 14);
      final b = DateTime(2026, 6, 15);
      expect(a.isSameDayAs(b), isFalse);
    });

    test('returns false for same day different month', () {
      final a = DateTime(2026, 6, 14);
      final b = DateTime(2026, 7, 14);
      expect(a.isSameDayAs(b), isFalse);
    });
  });

  group('StringX.capitalize', () {
    test('capitalizes first letter', () {
      expect('hello'.capitalize, 'Hello');
      expect('world'.capitalize, 'World');
    });

    test('leaves already-capitalized string unchanged', () {
      expect('Hello'.capitalize, 'Hello');
    });

    test('handles empty string', () {
      expect(''.capitalize, '');
    });

    test('handles single character', () {
      expect('a'.capitalize, 'A');
    });
  });
}
