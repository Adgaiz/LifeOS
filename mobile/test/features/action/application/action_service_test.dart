import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/action/application/action_service.dart';
import 'package:lifeos/features/action/domain/action_repository.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

void main() {
  late _MemoryActionRepository repository;
  late ActionService service;

  setUp(() {
    repository = _MemoryActionRepository();
    service = ActionService(
      repository,
      now: () => DateTime.utc(2026, 7, 29, 8),
    );
  });

  test('normalizes and adds a minimum action', () async {
    await service.add(
      localDate: CalendarDate(2026, 7, 29),
      title: '  跑步 5 公里  ',
      category: ActionCategory.health,
      minimumAction: '  散步 10 分钟  ',
      goalId: '00000000-0000-4000-8000-000000000020',
    );

    final action = repository.items.single;
    expect(action.title, '跑步 5 公里');
    expect(action.minimumAction, '散步 10 分钟');
    expect(action.goalId, '00000000-0000-4000-8000-000000000020');
    expect(action.status, ActionStatus.pending);
    expect(action.version, 1);
  });

  test('rejects an empty title', () {
    expect(
      () => service.add(
        localDate: CalendarDate(2026, 7, 29),
        title: '   ',
        category: ActionCategory.life,
      ),
      throwsA(isA<ActionValidationException>()),
    );
  });
}

final class _MemoryActionRepository implements ActionRepository {
  final List<DailyAction> items = [];

  @override
  Future<void> add(DailyAction action) async => items.add(action);

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    items.removeWhere((action) => action.id == id);
  }

  @override
  Future<void> updateStatus(
    String id,
    ActionStatus status,
    DateTime updatedAt,
  ) async {}

  @override
  Stream<List<DailyAction>> watchByDate(CalendarDate date) {
    return Stream.value(items);
  }
}
