import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/app/startup/foundation_page.dart';
import 'package:lifeos/features/ai/presentation/ai_settings_page.dart';
import 'package:lifeos/features/ai_companion/daily_review/presentation/daily_review_page.dart';
import 'package:lifeos/features/ai_companion/friend/presentation/ai_friend_page.dart';
import 'package:lifeos/features/ai_companion/periodic_report/presentation/periodic_report_page.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/analytics/presentation/analytics_page.dart';
import 'package:lifeos/features/daily/presentation/daily_home_page.dart';
import 'package:lifeos/features/diary/presentation/diary_page.dart';
import 'package:lifeos/features/goal/presentation/goal_page.dart';
import 'package:lifeos/features/timeline/presentation/timeline_page.dart';
import 'package:lifeos/features/vision/presentation/vision_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const FoundationPage()),
      GoRoute(
        path: '/today',
        builder: (context, state) => const DailyHomePage(),
      ),
      GoRoute(path: '/vision', builder: (context, state) => const VisionPage()),
      GoRoute(path: '/goals', builder: (context, state) => const GoalPage()),
      GoRoute(path: '/diary', builder: (context, state) => const DiaryPage()),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const TimelinePage(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: '/settings/ai',
        builder: (context, state) => const AiSettingsPage(),
      ),
      GoRoute(
        path: '/ai/daily-review',
        builder: (context, state) => const DailyReviewPage(),
      ),
      GoRoute(
        path: '/ai/friend',
        builder: (context, state) => const AiFriendPage(),
      ),
      GoRoute(
        path: '/ai/periodic-report',
        builder: (context, state) {
          final periodName = state.uri.queryParameters['period'];
          final period = AnalyticsPeriod.values.firstWhere(
            (value) => value.name == periodName,
            orElse: () => AnalyticsPeriod.sevenDays,
          );
          return PeriodicReportPage(initialPeriod: period);
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
