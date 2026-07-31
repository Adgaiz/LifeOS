import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image_lib;
import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:lifeos/features/diary/domain/diary_attachment_store.dart';
import 'package:path/path.dart' as path;

typedef DiaryRootDirectoryProvider = Future<Directory> Function();

final class PrivateDiaryAttachmentStore implements DiaryAttachmentStore {
  const PrivateDiaryAttachmentStore(this._rootDirectoryProvider);

  static const _maximumSourceBytes = 20 * 1024 * 1024;
  static const _maximumSourcePixels = 80 * 1000 * 1000;
  static const _masterMaximumEdge = 2048;
  static const _thumbnailMaximumEdge = 480;

  final DiaryRootDirectoryProvider _rootDirectoryProvider;

  @override
  Future<StagedDiaryImage> stageImage(String sourcePath, String id) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const DiaryImageException('选择的图片已不存在，请重新选择');
    }
    final sourceSize = await source.length();
    if (sourceSize <= 0 || sourceSize > _maximumSourceBytes) {
      throw const DiaryImageException('单张图片需要小于 20 MB');
    }
    final sourceBytes = await source.readAsBytes();
    final decoded = image_lib.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const DiaryImageException('暂不支持这张图片的格式');
    }
    if (decoded.width * decoded.height > _maximumSourcePixels) {
      throw const DiaryImageException('图片分辨率过高，请选择较小的图片');
    }

    final oriented = image_lib.bakeOrientation(decoded);
    final master = _resizeToFit(oriented, _masterMaximumEdge);
    final thumbnail = _resizeToFit(master, _thumbnailMaximumEdge);
    final masterBytes = image_lib.encodeJpg(master, quality: 88);
    final thumbnailBytes = image_lib.encodeJpg(thumbnail, quality: 76);
    final relativePath = path.posix.join('diary', 'pending', '$id.jpg');
    final thumbnailRelativePath = path.posix.join(
      'diary',
      'pending',
      '${id}_thumbnail.jpg',
    );
    await _writeAtomically(relativePath, masterBytes);
    try {
      await _writeAtomically(thumbnailRelativePath, thumbnailBytes);
    } catch (_) {
      await _deleteIfExists(relativePath);
      rethrow;
    }
    return StagedDiaryImage(
      id: id,
      relativePath: relativePath,
      thumbnailRelativePath: thumbnailRelativePath,
      mediaType: 'image/jpeg',
      sizeBytes: masterBytes.length,
      width: master.width,
      height: master.height,
      checksumSha256: sha256.convert(masterBytes).toString(),
    );
  }

  @override
  Future<StagedDiaryImage> promoteImage(StagedDiaryImage image) async {
    final relativePath = path.posix.join(
      'diary',
      'attachments',
      '${image.id}.jpg',
    );
    final thumbnailRelativePath = path.posix.join(
      'diary',
      'attachments',
      '${image.id}_thumbnail.jpg',
    );
    final stagedMaster = await _resolve(image.relativePath);
    final stagedThumbnail = await _resolve(image.thumbnailRelativePath);
    if (!await stagedMaster.exists() || !await stagedThumbnail.exists()) {
      throw const DiaryImageException('待保存图片已失效，请重新选择');
    }
    await _writeAtomically(relativePath, await stagedMaster.readAsBytes());
    try {
      await _writeAtomically(
        thumbnailRelativePath,
        await stagedThumbnail.readAsBytes(),
      );
    } catch (_) {
      await _deleteIfExists(relativePath);
      rethrow;
    }
    return StagedDiaryImage(
      id: image.id,
      relativePath: relativePath,
      thumbnailRelativePath: thumbnailRelativePath,
      mediaType: image.mediaType,
      sizeBytes: image.sizeBytes,
      width: image.width,
      height: image.height,
      checksumSha256: image.checksumSha256,
    );
  }

  @override
  Future<void> discardStagedImage(StagedDiaryImage image) async {
    await _deleteIfExists(image.relativePath);
    await _deleteIfExists(image.thumbnailRelativePath);
  }

  @override
  Future<void> deleteStoredPaths(
    String relativePath,
    String thumbnailRelativePath,
  ) async {
    await _deleteIfExists(relativePath);
    await _deleteIfExists(thumbnailRelativePath);
  }

  @override
  Future<void> deleteStagedFilesBefore(DateTime cutoff) async {
    final pendingDirectory = await _resolveDirectory(
      path.posix.join('diary', 'pending'),
    );
    if (!await pendingDirectory.exists()) {
      return;
    }
    await for (final entity in pendingDirectory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final modifiedAt = await entity.lastModified();
      if (modifiedAt.isBefore(cutoff)) {
        await entity.delete();
      }
    }
  }

  @override
  Future<String> resolveAbsolutePath(String relativePath) async {
    return (await _resolve(relativePath)).path;
  }

  image_lib.Image _resizeToFit(image_lib.Image source, int maximumEdge) {
    if (source.width <= maximumEdge && source.height <= maximumEdge) {
      return source;
    }
    if (source.width >= source.height) {
      return image_lib.copyResize(
        source,
        width: maximumEdge,
        interpolation: image_lib.Interpolation.average,
      );
    }
    return image_lib.copyResize(
      source,
      height: maximumEdge,
      interpolation: image_lib.Interpolation.average,
    );
  }

  Future<void> _writeAtomically(String relativePath, List<int> bytes) async {
    final destination = await _resolve(relativePath);
    await destination.parent.create(recursive: true);
    final temporary = File('${destination.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    if (await destination.exists()) {
      await destination.delete();
    }
    await temporary.rename(destination.path);
  }

  Future<void> _deleteIfExists(String relativePath) async {
    final file = await _resolve(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _resolve(String relativePath) async {
    if (relativePath.contains('\\') ||
        path.posix.isAbsolute(relativePath) ||
        path.posix.split(relativePath).contains('..')) {
      throw ArgumentError.value(relativePath, 'relativePath', 'Unsafe path');
    }
    final root = await _rootDirectoryProvider();
    final resolved = path.normalize(
      path.joinAll([root.path, ...path.posix.split(relativePath)]),
    );
    if (!path.isWithin(path.normalize(root.path), resolved)) {
      throw ArgumentError.value(relativePath, 'relativePath', 'Unsafe path');
    }
    return File(resolved);
  }

  Future<Directory> _resolveDirectory(String relativePath) async {
    final file = await _resolve(path.posix.join(relativePath, '.keep'));
    return file.parent;
  }
}
