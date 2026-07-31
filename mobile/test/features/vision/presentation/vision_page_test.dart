import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/vision/application/vision_providers.dart';
import 'package:lifeos/features/vision/domain/vision.dart';
import 'package:lifeos/features/vision/domain/vision_repository.dart';
import 'package:lifeos/features/vision/presentation/vision_page.dart';

void main() {
  testWidgets('creates the first vision from the empty state', (tester) async {
    final repository = _ReactiveVisionRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [visionRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: VisionPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('人生愿景'), findsOneWidget);
    expect(find.text('给未来一个方向'), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('愿景'), findsOneWidget);

    await tester.tap(find.text('写下第一个愿景'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '30 岁的我');
    await tester.enterText(fields.at(1), '保持健康，持续学习，也珍惜关系。');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(repository.items.single.title, '30 岁的我');
    expect(find.text('30 岁的我'), findsOneWidget);
  });
}

final class _ReactiveVisionRepository implements VisionRepository {
  final List<Vision> items = [];
  final StreamController<List<Vision>> _changes = StreamController.broadcast();

  void close() => _changes.close();

  @override
  Future<Vision?> findById(String id) async {
    return items.where((vision) => vision.id == id).firstOrNull;
  }

  @override
  Future<void> save(Vision vision) async {
    items.removeWhere((item) => item.id == vision.id);
    items.add(vision);
    _changes.add(List.unmodifiable(items));
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    items.removeWhere((vision) => vision.id == id);
    _changes.add(List.unmodifiable(items));
  }

  @override
  Future<void> updateStatus(
    String id,
    VisionStatus status,
    DateTime updatedAt,
  ) async {}

  @override
  Stream<List<Vision>> watchAll() async* {
    yield List.unmodifiable(items);
    yield* _changes.stream;
  }
}
