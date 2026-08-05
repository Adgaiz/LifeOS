import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

abstract interface class AnalyticsRepository {
  Future<AnalyticsSourceData> load(
    CalendarDate startDate,
    CalendarDate endDate,
  );
}
