final class CalendarDate implements Comparable<CalendarDate> {
  factory CalendarDate(int year, int month, int day) {
    if (year < 1 || year > 9999) {
      throw ArgumentError.value(year, 'year', 'Must be between 1 and 9999');
    }
    final normalized = DateTime(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError.value(
        '$year-$month-$day',
        'date',
        'Invalid calendar date',
      );
    }
    return CalendarDate._(year, month, day);
  }

  const CalendarDate._(this.year, this.month, this.day);

  factory CalendarDate.fromDateTime(DateTime value) {
    final local = value.toLocal();
    return CalendarDate(local.year, local.month, local.day);
  }

  factory CalendarDate.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('Invalid calendar date', value);
    }
    try {
      return CalendarDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    } on ArgumentError {
      throw FormatException('Invalid calendar date', value);
    }
  }

  final int year;
  final int month;
  final int day;

  DateTime toLocalDateTime() => DateTime(year, month, day);

  CalendarDate addDays(int days) {
    final result = DateTime.utc(year, month, day).add(Duration(days: days));
    return CalendarDate(result.year, result.month, result.day);
  }

  int daysUntil(CalendarDate other) {
    final start = DateTime.utc(year, month, day);
    final end = DateTime.utc(other.year, other.month, other.day);
    return end.difference(start).inDays;
  }

  String toIso8601String() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(CalendarDate other) =>
      toIso8601String().compareTo(other.toIso8601String());

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso8601String();
}

String timeZoneOffsetId(DateTime value) {
  final offset = value.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final absoluteMinutes = offset.inMinutes.abs();
  final hours = (absoluteMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (absoluteMinutes % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hours:$minutes';
}
