import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/timeline/domain/timeline_event.dart';
import 'package:lifeos/features/timeline/domain/timeline_repository.dart';
import 'package:uuid/uuid.dart';

final class TimelineService {
  TimelineService(this._repository, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final TimelineRepository _repository;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> save(TimelineEventInput input) async {
    final normalized = input.validateAndNormalize();
    final currentTime = _now();
    final today = CalendarDate.fromDateTime(currentTime);
    if (input.occurredOn.compareTo(today) > 0) {
      throw const TimelineValidationException('人生节点不能晚于今天');
    }

    final existing = input.id == null
        ? null
        : await _repository.findById(input.id!);
    if (input.id != null && existing == null) {
      throw StateError('Timeline event not found: ${input.id}');
    }
    if (existing != null && !existing.isManual) {
      throw StateError('System timeline events cannot be edited manually');
    }

    final nowUtc = currentTime.toUtc();
    await _repository.save(
      TimelineEvent(
        id: existing?.id ?? _uuid.v4(),
        occurredOn: input.occurredOn,
        type: input.type,
        title: normalized.title,
        description: normalized.description,
        sourceType: TimelineSourceType.manual,
        createdAt: existing?.createdAt ?? nowUtc,
        updatedAt: nowUtc,
        version: (existing?.version ?? 0) + 1,
      ),
    );
  }

  Future<void> delete(String id) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw StateError('Timeline event not found: $id');
    }
    if (!existing.isManual) {
      throw StateError('System timeline events cannot be deleted manually');
    }
    await _repository.softDelete(id, _now().toUtc());
  }
}
