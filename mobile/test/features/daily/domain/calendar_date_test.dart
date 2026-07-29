import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

void main() {
  test('round trips a valid calendar date', () {
    final date = CalendarDate.parse('2026-07-29');

    expect(date, CalendarDate(2026, 7, 29));
    expect(date.toIso8601String(), '2026-07-29');
  });

  test('rejects an impossible calendar date', () {
    expect(
      () => CalendarDate.parse('2026-02-30'),
      throwsA(isA<FormatException>()),
    );
    expect(() => CalendarDate(2026, 2, 30), throwsA(isA<ArgumentError>()));
  });

  test('formats positive and negative timezone offsets', () {
    expect(
      timeZoneOffsetId(DateTime.parse('2026-07-29T12:00:00+08:00')),
      startsWith('UTC'),
    );
  });
}
