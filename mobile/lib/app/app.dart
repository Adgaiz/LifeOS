import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/app/router/app_router.dart';
import 'package:lifeos/app/theme/lifeos_theme.dart';

final class LifeOsApp extends ConsumerWidget {
  const LifeOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'LifeOS',
      debugShowCheckedModeBanner: false,
      theme: LifeOsTheme.light,
      darkTheme: LifeOsTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
