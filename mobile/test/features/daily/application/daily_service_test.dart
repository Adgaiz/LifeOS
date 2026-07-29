import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/daily/application/daily_service.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/daily/domain/daily_repository.dart';

void main() {
  late _MemoryDailyRepository repository;
  late DailyService service;

  setUp(() {
    repository = _MemoryDailyRepository();
    service = DailyService(repository, now: () => DateTime.utc(2026, 7, 29, 8));
  });

  test('creates and then updates one record for the same day', () async {
    final date = CalendarDate(2026, 7, 29);
    await service.saveCheckIn(
      DailyCheckInInput(
        localDate: date,
        timezone: 'UTC+08:00',
        sleepMinutes: 450,
        mood: MoodLevel.good,
      ),
    );
    final first = repository.saved.single;

    await service.saveCheckIn(
      DailyCheckInInput(
        localDate: date,
        timezone: 'UTC+08:00',
        sleepMinutes: 480,
        mood: MoodLevel.bright,
      ),
    );
    final updated = repository.saved.single;

    expect(updated.id, first.id);
    expect(updated.sleepMinutes, 480);
    expect(updated.version, 2);
  });

  test('rejects invalid sleep duration', () async {
    expect(
      () => service.saveCheckIn(
        DailyCheckInInput(
          localDate: CalendarDate(2026, 7, 29),
          timezone: 'UTC+08:00',
          sleepMinutes: 1441,
        ),
      ),
      throwsA(isA<DailyValidationException>()),
    );
  });
}

final class _MemoryDailyRepository implements DailyRepository {
  final List<DailyRecord> saved = [];

  @override
  Future<DailyRecord?> findByDate(CalendarDate date, String timezone) async {
    return saved
        .where(
          (record) => record.localDate == date && record.timezone == timezone,
        )
        .firstOrNull;
  }

  @override
  Future<void> save(DailyRecord record) async {
    saved.removeWhere((item) => item.id == record.id);
    saved.add(record);
  }

  @override
  Stream<DailyRecord?> watchByDate(CalendarDate date, String timezone) {
    return Stream.value(null);
  }
}
