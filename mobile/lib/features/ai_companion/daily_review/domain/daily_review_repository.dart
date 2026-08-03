import 'package:lifeos/features/ai_companion/daily_review/domain/daily_review.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

abstract interface class DailyReviewRepository {
  Future<AiDailyReview?> findLatest(CalendarDate date);

  Future<void> save(AiDailyReview review);
}
