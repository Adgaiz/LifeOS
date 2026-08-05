import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/features/analytics/application/analytics_service.dart';
import 'package:lifeos/features/analytics/data/drift_analytics_repository.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/analytics/domain/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return DriftAnalyticsRepository(ref.watch(appDatabaseProvider));
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(analyticsRepositoryProvider));
});

final analyticsReportProvider = FutureProvider.autoDispose
    .family<AnalyticsReport, AnalyticsPeriod>((ref, period) {
      return ref.watch(analyticsServiceProvider).buildReport(period);
    });
