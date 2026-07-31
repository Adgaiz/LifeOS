import 'package:lifeos/features/goal/domain/goal.dart';

abstract interface class GoalRepository {
  Stream<List<GoalAggregate>> watchAll();

  Future<GoalAggregate?> findById(String id);

  Future<void> save(GoalAggregate aggregate);

  Future<void> updateStatus(String id, GoalStatus status, DateTime updatedAt);

  Future<void> updateKeyResultProgress(
    String keyResultId,
    int progress,
    DateTime updatedAt,
  );

  Future<void> softDelete(String id, DateTime deletedAt);
}
