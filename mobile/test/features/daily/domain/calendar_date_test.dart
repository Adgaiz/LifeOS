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

  test('adds and counts calendar days across a leap day', () {
    final start = CalendarDate(2028, 2, 28);
    final end = start.addDays(2);

    expect(end, CalendarDate(2028, 3, 1));
    expect(start.daysUntil(end), 2);
    expect(end.daysUntil(start), -2);
  });

  test('formats positive and negative timezone offsets', () {
    expect(
      timeZoneOffsetId(DateTime.parse('2026-07-29T12:00:00+08:00')),
      startsWith('UTC'),
    );
  });
}
