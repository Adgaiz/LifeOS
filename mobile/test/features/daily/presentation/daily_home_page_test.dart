import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/action/application/action_providers.dart';
import 'package:lifeos/features/action/domain/action_repository.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/daily/domain/daily_repository.dart';
import 'package:lifeos/features/daily/presentation/daily_home_page.dart';

void main() {
  testWidgets('shows the empty today experience', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyRepositoryProvider.overrideWithValue(
            const _EmptyDailyRepository(),
          ),
          actionRepositoryProvider.overrideWithValue(
            const _EmptyActionRepository(),
          ),
          currentDateTimeProvider.overrideWithValue(DateTime(2026, 7, 29, 9)),
        ],
        child: const MaterialApp(home: DailyHomePage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('今天，周三'), findsOneWidget);
    expect(find.text('今日状态'), findsOneWidget);
    expect(find.text('今天还没有行动'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('AI 当日复盘'), findsOneWidget);
    expect(find.text('一起回顾今天'), findsOneWidget);
    expect(find.text('聊聊此刻'), findsOneWidget);
  });
}

final class _EmptyDailyRepository implements DailyRepository {
  const _EmptyDailyRepository();

  @override
  Future<DailyRecord?> findByDate(CalendarDate date, String timezone) async {
    return null;
  }

  @override
  Future<void> save(DailyRecord record) async {}

  @override
  Stream<DailyRecord?> watchByDate(CalendarDate date, String timezone) {
    return Stream.value(null);
  }
}

final class _EmptyActionRepository implements ActionRepository {
  const _EmptyActionRepository();

  @override
  Future<void> add(DailyAction action) async {}

  @override
  Future<List<DailyAction>> findByDate(CalendarDate date) async => const [];

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {}

  @override
  Future<void> updateStatus(
    String id,
    ActionStatus status,
    DateTime updatedAt,
  ) async {}

  @override
  Stream<List<DailyAction>> watchByDate(CalendarDate date) {
    return Stream.value(const []);
  }
}
