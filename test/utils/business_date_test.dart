import 'package:flutter_test/flutter_test.dart';

/// Calcola il giorno lavorativo del ristorante.
/// Il giorno lavorativo va dalle 6:00 alle 5:59 del giorno dopo.
DateTime getBusinessDate(DateTime dateTime) {
  if (dateTime.hour < 6) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day - 1);
  }
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

void main() {
  group('Business Date Logic', () {
    test('orders at 20:00 belong to same day', () {
      final orderTime = DateTime(2024, 1, 15, 20, 0); // 15 Jan 20:00
      final businessDate = getBusinessDate(orderTime);
      expect(businessDate.day, 15);
      expect(businessDate.month, 1);
    });

    test('orders at 23:59 belong to same day', () {
      final orderTime = DateTime(2024, 1, 15, 23, 59); // 15 Jan 23:59
      final businessDate = getBusinessDate(orderTime);
      expect(businessDate.day, 15);
    });

    test('orders at 00:30 belong to previous day', () {
      final orderTime = DateTime(2024, 1, 16, 0, 30); // 16 Jan 00:30
      final businessDate = getBusinessDate(orderTime);
      expect(businessDate.day, 15); // Should be 15 Jan
    });

    test('orders at 05:59 belong to previous day', () {
      final orderTime = DateTime(2024, 1, 16, 5, 59); // 16 Jan 05:59
      final businessDate = getBusinessDate(orderTime);
      expect(businessDate.day, 15); // Should be 15 Jan
    });

    test('orders at 06:00 belong to new day', () {
      final orderTime = DateTime(2024, 1, 16, 6, 0); // 16 Jan 06:00
      final businessDate = getBusinessDate(orderTime);
      expect(businessDate.day, 16); // Should be 16 Jan
    });

    test('handles month boundary correctly', () {
      // 1 Feb at 02:00 should be 31 Jan business day
      final orderTime = DateTime(2024, 2, 1, 2, 0);
      final businessDate = getBusinessDate(orderTime);
      expect(businessDate.day, 31);
      expect(businessDate.month, 1);
    });

    test('handles year boundary correctly', () {
      // 1 Jan at 03:00 should be 31 Dec business day
      final orderTime = DateTime(2024, 1, 1, 3, 0);
      final businessDate = getBusinessDate(orderTime);
      expect(businessDate.day, 31);
      expect(businessDate.month, 12);
      expect(businessDate.year, 2023);
    });
  });
}
