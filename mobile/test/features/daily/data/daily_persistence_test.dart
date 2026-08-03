import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/features/action/data/drift_action_repository.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/daily/data/drift_daily_repository.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';

void main() {
  late AppDatabase database;
  late DriftDailyRepository dailyRepository;
  late DriftActionRepository actionRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dailyRepository = DriftDailyRepository(database);
    actionRepository = DriftActionRepository(database);
  });

  tearDown(() => database.close());

  test('persists a daily record with fixed precision weight', () async {
    final now = DateTime.utc(2026, 7, 29, 8);
    await dailyRepository.save(
      DailyRecord(
        id: '00000000-0000-4000-8000-000000000001',
        localDate: CalendarDate(2026, 7, 29),
        timezone: 'UTC+08:00',
        sleepMinutes: 455,
        mood: MoodLevel.good,
        energy: EnergyLevel.steady,
        weightGrams: 70150,
        exerciseMinutes: 30,
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
    );

    final record = await dailyRepository.findByDate(
      CalendarDate(2026, 7, 29),
      'UTC+08:00',
    );

    expect(record?.weightGrams, 70150);
    expect(record?.mood, MoodLevel.good);
    expect(record?.sleepMinutes, 455);
  });

  test('updates status and hides a soft-deleted action', () async {
    final now = DateTime.utc(2026, 7, 29, 8);
    const id = '00000000-0000-4000-8000-000000000002';
    await actionRepository.add(
      DailyAction(
        id: id,
        localDate: CalendarDate(2026, 7, 29),
        title: '散步 10 分钟',
        category: ActionCategory.health,
        status: ActionStatus.pending,
        position: 1,
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
    );
    await actionRepository.updateStatus(id, ActionStatus.partial, now);

    final updated = await actionRepository
        .watchByDate(CalendarDate(2026, 7, 29))
        .first;
    final loaded = await actionRepository.findByDate(CalendarDate(2026, 7, 29));
    expect(updated.single.status, ActionStatus.partial);
    expect(updated.single.version, 2);
    expect(loaded.single.status, ActionStatus.partial);

    await actionRepository.softDelete(id, now.add(const Duration(minutes: 1)));
    final visible = await actionRepository
        .watchByDate(CalendarDate(2026, 7, 29))
        .first;
    expect(visible, isEmpty);
  });
}
