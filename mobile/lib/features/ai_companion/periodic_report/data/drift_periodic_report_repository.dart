import 'package:drift/drift.dart';
import 'package:lifeos/core/database/app_database.dart' as db;
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai_companion/periodic_report/domain/periodic_report.dart';
import 'package:lifeos/features/ai_companion/periodic_report/domain/periodic_report_repository.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

final class DriftPeriodicReportRepository implements PeriodicReportRepository {
  const DriftPeriodicReportRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<AiPeriodicReport?> findLatest(
    AnalyticsPeriod period,
    CalendarDate startDate,
    CalendarDate endDate,
  ) async {
    final query = _database.select(_database.aiPeriodicReports)
      ..where(
        (table) =>
            table.periodType.equals(period.name) &
            table.startDate.equals(startDate.toIso8601String()) &
            table.endDate.equals(endDate.toIso8601String()) &
            table.deletedAt.isNull(),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(AiPeriodicReport report) async {
    await _database
        .into(_database.aiPeriodicReports)
        .insert(
          db.AiPeriodicReportsCompanion.insert(
            id: report.id,
            periodType: report.period.name,
            startDate: report.startDate.toIso8601String(),
            endDate: report.endDate.toIso8601String(),
            content: report.content,
            provider: report.provider.name,
            model: report.model,
            contextTypes: PeriodicReportContextType.values
                .where(report.contextTypes.contains)
                .map((type) => type.name)
                .join(','),
            promptVersion: Value(report.promptVersion),
            requestId: Value(report.requestId),
            inputTokens: Value(report.inputTokens),
            outputTokens: Value(report.outputTokens),
            createdAt: report.createdAt,
            version: Value(report.version),
          ),
        );
  }

  AiPeriodicReport _toDomain(db.AiPeriodicReportRow row) {
    return AiPeriodicReport(
      id: row.id,
      period: AnalyticsPeriod.values.firstWhere(
        (period) => period.name == row.periodType,
      ),
      startDate: CalendarDate.parse(row.startDate),
      endDate: CalendarDate.parse(row.endDate),
      content: row.content,
      provider: AiProviderType.values.firstWhere(
        (provider) => provider.name == row.provider,
      ),
      model: row.model,
      contextTypes: row.contextTypes
          .split(',')
          .map(PeriodicReportContextType.fromStorage)
          .toSet(),
      promptVersion: row.promptVersion,
      requestId: row.requestId,
      inputTokens: row.inputTokens,
      outputTokens: row.outputTokens,
      createdAt: row.createdAt,
      version: row.version,
    );
  }
}
