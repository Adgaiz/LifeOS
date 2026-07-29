import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/features/action/application/action_service.dart';
import 'package:lifeos/features/action/data/drift_action_repository.dart';
import 'package:lifeos/features/action/domain/action_repository.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';

final actionRepositoryProvider = Provider<ActionRepository>((ref) {
  return DriftActionRepository(ref.watch(appDatabaseProvider));
});

final actionServiceProvider = Provider<ActionService>((ref) {
  return ActionService(ref.watch(actionRepositoryProvider));
});

final todayActionsProvider = StreamProvider.autoDispose<List<DailyAction>>((
  ref,
) {
  return ref
      .watch(actionRepositoryProvider)
      .watchByDate(ref.watch(todayProvider));
});
