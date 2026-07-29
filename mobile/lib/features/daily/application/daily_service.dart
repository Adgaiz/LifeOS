import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/daily/domain/daily_repository.dart';
import 'package:uuid/uuid.dart';

final class DailyService {
  DailyService(this._repository, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final DailyRepository _repository;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> saveCheckIn(DailyCheckInInput input) async {
    input.validate();
    final existing = await _repository.findByDate(
      input.localDate,
      input.timezone,
    );
    final now = _now().toUtc();
    final record = DailyRecord(
      id: existing?.id ?? _uuid.v4(),
      localDate: input.localDate,
      timezone: input.timezone,
      sleepMinutes: input.sleepMinutes,
      mood: input.mood,
      energy: input.energy,
      weightGrams: input.weightGrams,
      exerciseMinutes: input.exerciseMinutes,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      version: (existing?.version ?? 0) + 1,
    );
    await _repository.save(record);
  }
}
