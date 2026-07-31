import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/app/startup/foundation_page.dart';
import 'package:lifeos/features/daily/presentation/daily_home_page.dart';
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
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
