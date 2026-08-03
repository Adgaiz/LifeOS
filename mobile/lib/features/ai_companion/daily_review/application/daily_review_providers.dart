import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/features/action/application/action_providers.dart';
import 'package:lifeos/features/ai/application/ai_providers.dart';
import 'package:lifeos/features/ai_companion/daily_review/application/daily_review_service.dart';
import 'package:lifeos/features/ai_companion/daily_review/data/drift_daily_review_repository.dart';
import 'package:lifeos/features/ai_companion/daily_review/domain/daily_review_repository.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/diary/application/diary_providers.dart';

final dailyReviewRepositoryProvider = Provider<DailyReviewRepository>((ref) {
  return DriftDailyReviewRepository(ref.watch(appDatabaseProvider));
});

final dailyReviewServiceProvider = Provider<DailyReviewService>((ref) {
  return DailyReviewService(
    ref.watch(dailyRepositoryProvider),
    ref.watch(actionRepositoryProvider),
    ref.watch(diaryRepositoryProvider),
    ref.watch(dailyReviewRepositoryProvider),
    ref.watch(aiServiceProvider),
  );
});
