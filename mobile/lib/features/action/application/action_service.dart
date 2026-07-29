import 'package:lifeos/features/action/domain/action_repository.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:uuid/uuid.dart';

final class ActionService {
  ActionService(this._repository, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final ActionRepository _repository;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> add({
    required CalendarDate localDate,
    required String title,
    required ActionCategory category,
    String? minimumAction,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedMinimum = minimumAction?.trim();
    if (normalizedTitle.isEmpty || normalizedTitle.length > 80) {
      throw const ActionValidationException('行动名称需要 1 到 80 个字符');
    }
    if (normalizedMinimum != null && normalizedMinimum.length > 120) {
      throw const ActionValidationException('最低行动不能超过 120 个字符');
    }
    final now = _now().toUtc();
    await _repository.add(
      DailyAction(
        id: _uuid.v4(),
        localDate: localDate,
        title: normalizedTitle,
        minimumAction: normalizedMinimum?.isEmpty ?? true
            ? null
            : normalizedMinimum,
        category: category,
        status: ActionStatus.pending,
        position: now.microsecondsSinceEpoch,
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
    );
  }

  Future<void> updateStatus(String id, ActionStatus status) {
    return _repository.updateStatus(id, status, _now().toUtc());
  }

  Future<void> delete(String id) {
    return _repository.softDelete(id, _now().toUtc());
  }
}
