import 'package:drift/drift.dart';
import 'package:lifeos/core/database/app_database.dart' as db;
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai_companion/daily_review/domain/daily_review.dart';
import 'package:lifeos/features/ai_companion/daily_review/domain/daily_review_repository.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

final class DriftDailyReviewRepository implements DailyReviewRepository {
  const DriftDailyReviewRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<AiDailyReview?> findLatest(CalendarDate date) async {
    final query = _database.select(_database.aiDailyReviews)
      ..where(
        (table) =>
            table.localDate.equals(date.toIso8601String()) &
            table.deletedAt.isNull(),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(AiDailyReview review) async {
    await _database
        .into(_database.aiDailyReviews)
        .insert(
          db.AiDailyReviewsCompanion.insert(
            id: review.id,
            localDate: review.localDate.toIso8601String(),
            content: review.content,
            provider: review.provider.name,
            model: review.model,
            contextTypes: review.contextTypes
                .map((type) => type.name)
                .join(','),
            promptVersion: Value(review.promptVersion),
            requestId: Value(review.requestId),
            inputTokens: Value(review.inputTokens),
            outputTokens: Value(review.outputTokens),
            createdAt: review.createdAt,
            version: Value(review.version),
          ),
        );
  }

  AiDailyReview _toDomain(db.AiDailyReviewRow row) {
    return AiDailyReview(
      id: row.id,
      localDate: CalendarDate.parse(row.localDate),
      content: row.content,
      provider: AiProviderType.values.firstWhere(
        (provider) => provider.name == row.provider,
      ),
      model: row.model,
      contextTypes: row.contextTypes
          .split(',')
          .map(DailyReviewContextType.fromStorage)
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
