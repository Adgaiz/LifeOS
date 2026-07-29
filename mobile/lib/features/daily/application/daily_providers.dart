import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/features/daily/application/daily_service.dart';
import 'package:lifeos/features/daily/data/drift_daily_repository.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/daily/domain/daily_repository.dart';

final currentDateTimeProvider = Provider<DateTime>((ref) => DateTime.now());

final todayProvider = Provider<CalendarDate>((ref) {
  return CalendarDate.fromDateTime(ref.watch(currentDateTimeProvider));
});

final currentTimeZoneProvider = Provider<String>((ref) {
  return timeZoneOffsetId(ref.watch(currentDateTimeProvider));
});

final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  return DriftDailyRepository(ref.watch(appDatabaseProvider));
});

final dailyServiceProvider = Provider<DailyService>((ref) {
  return DailyService(ref.watch(dailyRepositoryProvider));
});

final todayRecordProvider = StreamProvider.autoDispose<DailyRecord?>((ref) {
  return ref
      .watch(dailyRepositoryProvider)
      .watchByDate(
        ref.watch(todayProvider),
        ref.watch(currentTimeZoneProvider),
      );
});
