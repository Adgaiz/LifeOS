import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/features/diary/application/diary_service.dart';
import 'package:lifeos/features/diary/data/drift_diary_repository.dart';
import 'package:lifeos/features/diary/data/private_diary_attachment_store.dart';
import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:lifeos/features/diary/domain/diary_attachment_store.dart';
import 'package:lifeos/features/diary/domain/diary_repository.dart';
import 'package:path_provider/path_provider.dart';

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DriftDiaryRepository(ref.watch(appDatabaseProvider));
});

final diaryAttachmentStoreProvider = Provider<DiaryAttachmentStore>((ref) {
  return PrivateDiaryAttachmentStore(getApplicationSupportDirectory);
});

final diaryServiceProvider = Provider<DiaryService>((ref) {
  return DiaryService(
    ref.watch(diaryRepositoryProvider),
    ref.watch(diaryAttachmentStoreProvider),
  );
});

final allDiaryEntriesProvider =
    StreamProvider.autoDispose<List<DiaryAggregate>>(
      (ref) => ref.watch(diaryRepositoryProvider).watchAll(),
    );

final diaryMaintenanceProvider = FutureProvider.autoDispose<void>((ref) {
  return ref.watch(diaryServiceProvider).runMaintenance();
});

final diaryAttachmentPathProvider = FutureProvider.autoDispose
    .family<String, String>((ref, relativePath) {
      return ref
          .watch(diaryAttachmentStoreProvider)
          .resolveAbsolutePath(relativePath);
    });
