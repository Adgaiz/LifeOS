import 'package:lifeos/features/daily/domain/calendar_date.dart';

enum MoodLevel {
  difficult(1, '低落'),
  low(2, '有点低'),
  steady(3, '平稳'),
  good(4, '不错'),
  bright(5, '很好');

  const MoodLevel(this.value, this.label);

  final int value;
  final String label;

  static MoodLevel fromValue(int value) => values.firstWhere(
    (level) => level.value == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'Invalid mood'),
  );
}

enum EnergyLevel {
  empty(1, '很疲惫'),
  low(2, '偏低'),
  steady(3, '平稳'),
  good(4, '充足'),
  full(5, '很充沛');

  const EnergyLevel(this.value, this.label);

  final int value;
  final String label;

  static EnergyLevel fromValue(int value) => values.firstWhere(
    (level) => level.value == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'Invalid energy'),
  );
}

final class DailyRecord {
  const DailyRecord({
    required this.id,
    required this.localDate,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.sleepMinutes,
    this.mood,
    this.energy,
    this.weightGrams,
    this.exerciseMinutes,
  });

  final String id;
  final CalendarDate localDate;
  final String timezone;
  final int? sleepMinutes;
  final MoodLevel? mood;
  final EnergyLevel? energy;
  final int? weightGrams;
  final int? exerciseMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class DailyCheckInInput {
  const DailyCheckInInput({
    required this.localDate,
    required this.timezone,
    this.sleepMinutes,
    this.mood,
    this.energy,
    this.weightGrams,
    this.exerciseMinutes,
  });

  final CalendarDate localDate;
  final String timezone;
  final int? sleepMinutes;
  final MoodLevel? mood;
  final EnergyLevel? energy;
  final int? weightGrams;
  final int? exerciseMinutes;

  void validate() {
    if (timezone.trim().isEmpty || timezone.length > 64) {
      throw const DailyValidationException('时区信息无效');
    }
    if (sleepMinutes != null &&
        (sleepMinutes! < 0 || sleepMinutes! > 24 * 60)) {
      throw const DailyValidationException('睡眠时间应在 0 到 24 小时之间');
    }
    if (weightGrams != null &&
        (weightGrams! < 1000 || weightGrams! > 1000000)) {
      throw const DailyValidationException('体重应在 1 到 1000 千克之间');
    }
    if (exerciseMinutes != null &&
        (exerciseMinutes! < 0 || exerciseMinutes! > 24 * 60)) {
      throw const DailyValidationException('运动时间应在 0 到 1440 分钟之间');
    }
  }
}

final class DailyValidationException implements Exception {
  const DailyValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
