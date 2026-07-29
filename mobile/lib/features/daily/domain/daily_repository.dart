import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';

abstract interface class DailyRepository {
  Stream<DailyRecord?> watchByDate(CalendarDate date, String timezone);

  Future<DailyRecord?> findByDate(CalendarDate date, String timezone);

  Future<void> save(DailyRecord record);
}
