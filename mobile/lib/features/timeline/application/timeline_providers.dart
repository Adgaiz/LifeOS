import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/features/timeline/application/timeline_service.dart';
import 'package:lifeos/features/timeline/data/drift_timeline_repository.dart';
import 'package:lifeos/features/timeline/domain/timeline_event.dart';
import 'package:lifeos/features/timeline/domain/timeline_repository.dart';

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return DriftTimelineRepository(ref.watch(appDatabaseProvider));
});

final timelineServiceProvider = Provider<TimelineService>((ref) {
  return TimelineService(ref.watch(timelineRepositoryProvider));
});

final allTimelineEventsProvider =
    StreamProvider.autoDispose<List<TimelineEvent>>((ref) {
      return ref.watch(timelineRepositoryProvider).watchAll();
    });
