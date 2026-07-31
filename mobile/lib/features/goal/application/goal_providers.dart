import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/features/goal/application/goal_service.dart';
import 'package:lifeos/features/goal/data/drift_goal_repository.dart';
import 'package:lifeos/features/goal/domain/goal.dart';
import 'package:lifeos/features/goal/domain/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return DriftGoalRepository(ref.watch(appDatabaseProvider));
});

final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService(ref.watch(goalRepositoryProvider));
});

final allGoalsProvider = StreamProvider.autoDispose<List<GoalAggregate>>((ref) {
  return ref.watch(goalRepositoryProvider).watchAll();
});
