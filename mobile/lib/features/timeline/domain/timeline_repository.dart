import 'package:lifeos/features/timeline/domain/timeline_event.dart';

abstract interface class TimelineRepository {
  Stream<List<TimelineEvent>> watchAll();

  Future<TimelineEvent?> findById(String id);

  Future<void> save(TimelineEvent event);

  Future<void> softDelete(String id, DateTime deletedAt);
}
