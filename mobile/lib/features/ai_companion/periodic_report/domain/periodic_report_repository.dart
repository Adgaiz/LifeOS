import 'package:lifeos/features/ai_companion/periodic_report/domain/periodic_report.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

abstract interface class PeriodicReportRepository {
  Future<AiPeriodicReport?> findLatest(
    AnalyticsPeriod period,
    CalendarDate startDate,
    CalendarDate endDate,
  );

  Future<void> save(AiPeriodicReport report);
}
