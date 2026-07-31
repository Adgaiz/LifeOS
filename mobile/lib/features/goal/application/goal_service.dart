import 'package:lifeos/features/goal/domain/goal.dart';
import 'package:lifeos/features/goal/domain/goal_repository.dart';
import 'package:uuid/uuid.dart';

final class GoalService {
  GoalService(this._repository, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final GoalRepository _repository;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> save(GoalInput input) async {
    final normalized = input.validateAndNormalize();
    final existing = input.id == null
        ? null
        : await _repository.findById(input.id!);
    if (input.id != null && existing == null) {
      throw StateError('Goal not found: ${input.id}');
    }
    final now = _now().toUtc();
    final goalId = existing?.goal.id ?? _uuid.v4();
    final existingKeyResults = {
      for (final keyResult in existing?.keyResults ?? <GoalKeyResult>[])
        keyResult.id: keyResult,
    };
    final keyResults = <GoalKeyResult>[];
    for (var index = 0; index < normalized.keyResults.length; index++) {
      final inputKeyResult = normalized.keyResults[index];
      final existingKeyResult = inputKeyResult.id == null
          ? null
          : existingKeyResults[inputKeyResult.id];
      if (inputKeyResult.id != null && existingKeyResult == null) {
        throw StateError('Goal key result not found: ${inputKeyResult.id}');
      }
      keyResults.add(
        GoalKeyResult(
          id: existingKeyResult?.id ?? _uuid.v4(),
          goalId: goalId,
          title: inputKeyResult.title,
          progress: inputKeyResult.progress,
          position: index,
          createdAt: existingKeyResult?.createdAt ?? now,
          updatedAt: now,
          version: (existingKeyResult?.version ?? 0) + 1,
        ),
      );
    }
    await _repository.save(
      GoalAggregate(
        goal: Goal(
          id: goalId,
          visionId: input.visionId,
          title: normalized.title,
          description: normalized.description,
          startDate: input.startDate,
          endDate: input.endDate,
          status: existing?.goal.status ?? GoalStatus.active,
          createdAt: existing?.goal.createdAt ?? now,
          updatedAt: now,
          version: (existing?.goal.version ?? 0) + 1,
        ),
        keyResults: keyResults,
      ),
    );
  }

  Future<void> updateKeyResultProgress(String id, int progress) {
    if (progress < 0 || progress > 100) {
      throw const GoalValidationException('关键结果进度需要在 0 到 100 之间');
    }
    return _repository.updateKeyResultProgress(id, progress, _now().toUtc());
  }

  Future<void> complete(String id) {
    return _repository.updateStatus(id, GoalStatus.completed, _now().toUtc());
  }

  Future<void> reopen(String id) {
    return _repository.updateStatus(id, GoalStatus.active, _now().toUtc());
  }

  Future<void> archive(String id) {
    return _repository.updateStatus(id, GoalStatus.archived, _now().toUtc());
  }

  Future<void> delete(String id) {
    return _repository.softDelete(id, _now().toUtc());
  }
}
