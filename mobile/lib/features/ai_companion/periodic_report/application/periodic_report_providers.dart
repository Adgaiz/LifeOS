import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/features/ai/application/ai_providers.dart';
import 'package:lifeos/features/ai_companion/periodic_report/application/periodic_report_service.dart';
import 'package:lifeos/features/ai_companion/periodic_report/data/drift_periodic_report_repository.dart';
import 'package:lifeos/features/ai_companion/periodic_report/domain/periodic_report_repository.dart';
import 'package:lifeos/features/analytics/application/analytics_providers.dart';

final periodicReportRepositoryProvider = Provider<PeriodicReportRepository>((
  ref,
) {
  return DriftPeriodicReportRepository(ref.watch(appDatabaseProvider));
});

final periodicReportServiceProvider = Provider<PeriodicReportService>((ref) {
  return PeriodicReportService(
    ref.watch(analyticsServiceProvider),
    ref.watch(periodicReportRepositoryProvider),
    ref.watch(aiServiceProvider),
  );
});
