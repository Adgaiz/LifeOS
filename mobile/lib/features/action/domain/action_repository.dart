import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

abstract interface class ActionRepository {
  Stream<List<DailyAction>> watchByDate(CalendarDate date);

  Future<List<DailyAction>> findByDate(CalendarDate date);

  Future<void> add(DailyAction action);

  Future<void> updateStatus(String id, ActionStatus status, DateTime updatedAt);

  Future<void> softDelete(String id, DateTime deletedAt);
}
