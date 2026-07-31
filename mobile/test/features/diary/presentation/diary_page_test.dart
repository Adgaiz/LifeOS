import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/diary/application/diary_providers.dart';
import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:lifeos/features/diary/domain/diary_attachment_store.dart';
import 'package:lifeos/features/diary/domain/diary_repository.dart';
import 'package:lifeos/features/diary/presentation/diary_page.dart';

void main() {
  testWidgets('creates the first daily markdown entry with tags', (
    tester,
  ) async {
    final repository = _ReactiveDiaryRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDateTimeProvider.overrideWithValue(DateTime(2026, 7, 31)),
          diaryRepositoryProvider.overrideWithValue(repository),
          diaryAttachmentStoreProvider.overrideWithValue(
            _MemoryAttachmentStore(),
          ),
        ],
        child: const MaterialApp(home: DiaryPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('人生记录'), findsOneWidget);
    expect(find.text('为今天留下一点痕迹'), findsOneWidget);
    expect(find.text('日记'), findsOneWidget);

    await tester.tap(find.text('写下第一篇日记'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(
      find.byType(TextFormField).first,
      '# 今天\n\n完成了 Diary 的第一次记录。',
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, '标签（可选）'),
      '成长，生活',
    );
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final saved = repository.items.single;
    expect(saved.entry.localDate, CalendarDate(2026, 7, 31));
    expect(saved.entry.markdown, '# 今天\n\n完成了 Diary 的第一次记录。');
    expect(saved.tags.map((tag) => tag.name), ['成长', '生活']);
    expect(find.text('2026年7月31日'), findsOneWidget);
    expect(find.text('#成长'), findsOneWidget);
  });
}

final class _ReactiveDiaryRepository implements DiaryRepository {
  final List<DiaryAggregate> items = [];
  final StreamController<List<DiaryAggregate>> _changes =
      StreamController.broadcast();

  void close() => _changes.close();

  @override
  Future<DiaryAggregate?> findByDate(CalendarDate date) async {
    return items.where((item) => item.entry.localDate == date).firstOrNull;
  }

  @override
  Future<DiaryAggregate?> findById(String id) async {
    return items.where((item) => item.entry.id == id).firstOrNull;
  }

  @override
  Future<List<DiaryAttachment>> findAttachmentsPendingFileDeletion(
    DateTime deletedBefore,
  ) async => const [];

  @override
  Future<void> markAttachmentFilesDeleted(
    String id,
    DateTime deletedAt,
  ) async {}

  @override
  Future<void> save(DiaryAggregate aggregate) async {
    items.removeWhere((item) => item.entry.id == aggregate.entry.id);
    items.add(aggregate);
    _changes.add(List.unmodifiable(items));
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    items.removeWhere((item) => item.entry.id == id);
    _changes.add(List.unmodifiable(items));
  }

  @override
  Stream<List<DiaryAggregate>> watchAll() async* {
    yield List.unmodifiable(items);
    yield* _changes.stream;
  }
}

final class _MemoryAttachmentStore implements DiaryAttachmentStore {
  @override
  Future<void> deleteStagedFilesBefore(DateTime cutoff) async {}

  @override
  Future<void> deleteStoredPaths(
    String relativePath,
    String thumbnailRelativePath,
  ) async {}

  @override
  Future<void> discardStagedImage(StagedDiaryImage image) async {}

  @override
  Future<StagedDiaryImage> promoteImage(StagedDiaryImage image) async => image;

  @override
  Future<String> resolveAbsolutePath(String relativePath) async => relativePath;

  @override
  Future<StagedDiaryImage> stageImage(String sourcePath, String id) {
    throw UnimplementedError();
  }
}
