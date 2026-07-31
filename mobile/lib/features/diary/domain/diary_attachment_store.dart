import 'package:lifeos/features/diary/domain/diary.dart';

abstract interface class DiaryAttachmentStore {
  Future<StagedDiaryImage> stageImage(String sourcePath, String id);

  Future<StagedDiaryImage> promoteImage(StagedDiaryImage image);

  Future<void> discardStagedImage(StagedDiaryImage image);

  Future<void> deleteStoredPaths(
    String relativePath,
    String thumbnailRelativePath,
  );

  Future<void> deleteStagedFilesBefore(DateTime cutoff);

  Future<String> resolveAbsolutePath(String relativePath);
}
