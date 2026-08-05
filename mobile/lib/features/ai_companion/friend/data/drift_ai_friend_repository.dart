import 'package:drift/drift.dart';
import 'package:lifeos/core/database/app_database.dart' as db;
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai_companion/friend/domain/ai_friend.dart';
import 'package:lifeos/features/ai_companion/friend/domain/ai_friend_repository.dart';

final class DriftAiFriendRepository implements AiFriendRepository {
  const DriftAiFriendRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<AiFriendExchange?> findLatest() async {
    final query = _database.select(_database.aiFriendExchanges)
      ..where((table) => table.deletedAt.isNull())
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(AiFriendExchange exchange) async {
    await _database
        .into(_database.aiFriendExchanges)
        .insert(
          db.AiFriendExchangesCompanion.insert(
            id: exchange.id,
            userMessage: exchange.userMessage,
            assistantMessage: exchange.assistantMessage,
            provider: Value(exchange.provider?.name),
            model: Value(exchange.model),
            safetyLevel: exchange.safetyLevel.name,
            promptVersion: Value(exchange.promptVersion),
            requestId: Value(exchange.requestId),
            inputTokens: Value(exchange.inputTokens),
            outputTokens: Value(exchange.outputTokens),
            createdAt: exchange.createdAt,
            version: Value(exchange.version),
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    final statement = _database.delete(_database.aiFriendExchanges)
      ..where((table) => table.id.equals(id));
    final affected = await statement.go();
    if (affected != 1) {
      throw StateError('AI Friend exchange not found: $id');
    }
  }

  AiFriendExchange _toDomain(db.AiFriendExchangeRow row) {
    return AiFriendExchange(
      id: row.id,
      userMessage: row.userMessage,
      assistantMessage: row.assistantMessage,
      safetyLevel: AiFriendSafetyLevel.fromStorage(row.safetyLevel),
      provider: row.provider == null
          ? null
          : AiProviderType.values.firstWhere(
              (provider) => provider.name == row.provider,
            ),
      model: row.model,
      promptVersion: row.promptVersion,
      requestId: row.requestId,
      inputTokens: row.inputTokens,
      outputTokens: row.outputTokens,
      createdAt: row.createdAt,
      version: row.version,
    );
  }
}
