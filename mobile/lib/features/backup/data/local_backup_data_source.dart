import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/core/storage/local_data_paths.dart';
import 'package:lifeos/features/backup/data/encrypted_backup_codec.dart';
import 'package:lifeos/features/backup/domain/backup_exception.dart';
import 'package:lifeos/features/backup/domain/backup_models.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

final class CreatedBackup {
  const CreatedBackup({
    required this.file,
    required this.workingDirectory,
    required this.summary,
  });

  final File file;
  final Directory workingDirectory;
  final BackupSummary summary;
}

/// Owns consistent snapshots, archive validation, and atomic local switching.
final class LocalBackupDataSource {
  factory LocalBackupDataSource({
    required AppDatabase database,
    required LocalDataPaths paths,
    required EncryptedBackupCodec codec,
    Uuid uuid = const Uuid(),
  }) {
    return LocalBackupDataSource._(database, paths, codec, uuid);
  }

  const LocalBackupDataSource._(
    this._database,
    this._paths,
    this._codec,
    this._uuid,
  );

  static const _databaseArchivePath = 'database/lifeos.sqlite';
  static const _manifestArchivePath = 'manifest.json';
  static const _filesPrefix = 'files/';
  static const _maximumArchiveEntries = 100000;
  static const _maximumArchiveFileSize = 2 * 1024 * 1024 * 1024;
  static const _maximumArchiveTotalSize = 10 * 1024 * 1024 * 1024;
  static const _entityTables = <String>[
    'app_metadata',
    'daily_records',
    'daily_actions',
    'visions',
    'goals',
    'goal_key_results',
    'diary_entries',
    'diary_tags',
    'diary_attachments',
    'ai_daily_reviews',
    'ai_friend_exchanges',
    'timeline_events',
    'ai_periodic_reports',
  ];

  final AppDatabase _database;
  final LocalDataPaths _paths;
  final EncryptedBackupCodec _codec;
  final Uuid _uuid;

  Future<CreatedBackup> create(String password) async {
    final root = await _createWorkingDirectory('create');
    try {
      final payload = Directory(path.join(root.path, 'payload'));
      await payload.create(recursive: true);
      final databaseSnapshot = File(
        path.joinAll([payload.path, ..._databaseArchivePath.split('/')]),
      );
      await databaseSnapshot.parent.create(recursive: true);
      await _createDatabaseSnapshot(databaseSnapshot);

      final fileRecords = <BackupFileRecord>[
        await _recordFor(databaseSnapshot, _databaseArchivePath),
      ];
      final attachments = await (_database.select(
        _database.diaryAttachments,
      )..where((table) => table.filesDeletedAt.isNull())).get();
      for (final attachment in attachments) {
        await _copyReferencedAttachment(
          attachment.relativePath,
          expectedSha256: attachment.checksumSha256,
          payload: payload,
          records: fileRecords,
        );
        await _copyReferencedAttachment(
          attachment.thumbnailRelativePath,
          payload: payload,
          records: fileRecords,
        );
      }

      final createdAt = DateTime.now().toUtc();
      final manifest = BackupManifest(
        createdAt: createdAt,
        schemaVersion: _database.schemaVersion,
        entityCounts: await _readEntityCounts(_database),
        files: fileRecords,
      );
      await File(
        path.join(payload.path, _manifestArchivePath),
      ).writeAsBytes(manifest.toJsonBytes(), flush: true);

      final zip = File(path.join(root.path, 'payload.zip'));
      await _createZip(payload, zip, fileRecords);
      final encrypted = File(path.join(root.path, 'lifeos.lifeos-backup'));
      await _codec.encrypt(input: zip, output: encrypted, password: password);

      // A backup is not reported as successful until it can be decrypted and
      // validated independently with the same path used by restore.
      final verification = await _prepare(
        encrypted,
        password,
        purpose: 'verify',
      );
      await cleanupPrepared(verification);
      return CreatedBackup(
        file: encrypted,
        workingDirectory: root,
        summary: BackupSummary(
          createdAt: createdAt,
          fileSize: await encrypted.length(),
          attachmentCount: attachments.length,
        ),
      );
    } catch (_) {
      await _deleteDirectory(root);
      rethrow;
    }
  }

  Future<PreparedRestore> prepareRestore(File encrypted, String password) {
    return _prepare(encrypted, password, purpose: 'restore');
  }

  Future<PreparedRestore> _prepare(
    File encrypted,
    String password, {
    required String purpose,
  }) async {
    final root = await _createWorkingDirectory(purpose);
    try {
      final zip = File(path.join(root.path, 'payload.zip'));
      await _codec.decrypt(input: encrypted, output: zip, password: password);
      final extracted = Directory(path.join(root.path, 'extracted'));
      await extracted.create(recursive: true);
      await _extractStrict(zip, extracted);

      final manifestFile = File(
        path.join(extracted.path, _manifestArchivePath),
      );
      if (!await manifestFile.exists()) {
        throw const BackupException('备份缺少清单文件', code: BackupErrorCode.damaged);
      }
      final manifest = BackupManifest.fromJsonBytes(
        await manifestFile.readAsBytes(),
      );
      if (manifest.schemaVersion > _database.schemaVersion) {
        throw const BackupException(
          '此备份来自更高版本的 LifeOS，请先升级应用',
          code: BackupErrorCode.incompatible,
        );
      }
      await _verifyManifest(extracted, manifest);
      final databaseFile = File(
        path.joinAll([extracted.path, ..._databaseArchivePath.split('/')]),
      );
      await _validateDatabase(databaseFile, manifest);
      return PreparedRestore(
        workingDirectoryPath: root.path,
        databasePath: databaseFile.path,
        attachmentsDirectoryPath: path.join(
          extracted.path,
          _filesPrefix,
          'diary',
          'attachments',
        ),
        manifest: manifest,
      );
    } catch (_) {
      await _deleteDirectory(root);
      rethrow;
    }
  }

  Future<void> commitRestore(
    PreparedRestore prepared, {
    bool closeCurrentDatabase = true,
  }) async {
    final databaseFile = await _paths.databaseFile();
    final documents = await _paths.documentsDirectory();
    final support = await _paths.supportDirectory();
    final token = _uuid.v4();
    final stagedDatabase = File(
      path.join(documents.path, '.lifeos_restore_$token.sqlite'),
    );
    final diaryDirectory = Directory(path.join(support.path, 'diary'));
    final currentAttachments = Directory(
      path.join(diaryDirectory.path, 'attachments'),
    );
    final stagedAttachments = Directory(
      path.join(diaryDirectory.path, '.attachments_stage_$token'),
    );
    final rollbackAttachments = Directory(
      path.join(diaryDirectory.path, '.attachments_rollback_$token'),
    );
    final rollbackDatabase = File('${databaseFile.path}.rollback_$token');
    final sidecarSuffixes = <String>['-wal', '-shm', '-journal'];
    final movedSidecars = <(File, File)>[];
    var databaseMoved = false;
    var stagedDatabaseInstalled = false;
    var attachmentsMoved = false;
    var stagedAttachmentsInstalled = false;
    var switchValidated = false;
    try {
      await File(prepared.databasePath).copy(stagedDatabase.path);
      await _copyDirectory(
        Directory(prepared.attachmentsDirectoryPath),
        stagedAttachments,
        allowMissingSource: true,
      );
      await _validateDatabase(stagedDatabase, prepared.manifest);

      // The app flow invalidates the database provider before reaching this
      // point. Keep the default close for direct callers and tests, while
      // allowing the provider-owned connection to be released by Riverpod.
      if (closeCurrentDatabase) {
        await _database.close().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw const BackupException(
            '当前数据库仍有页面正在使用，请返回今天页面后重试',
            code: BackupErrorCode.busy,
          ),
        );
      }
      for (final suffix in sidecarSuffixes) {
        final sidecar = File('${databaseFile.path}$suffix');
        if (await sidecar.exists()) {
          final rollback = File('${rollbackDatabase.path}$suffix');
          await sidecar.rename(rollback.path);
          movedSidecars.add((sidecar, rollback));
        }
      }
      if (await databaseFile.exists()) {
        await databaseFile.rename(rollbackDatabase.path);
        databaseMoved = true;
      }
      await stagedDatabase.rename(databaseFile.path);
      stagedDatabaseInstalled = true;

      await diaryDirectory.create(recursive: true);
      if (await currentAttachments.exists()) {
        await currentAttachments.rename(rollbackAttachments.path);
        attachmentsMoved = true;
      }
      await stagedAttachments.rename(currentAttachments.path);
      stagedAttachmentsInstalled = true;

      await _validateStandaloneDatabase(databaseFile);
      switchValidated = true;
      if (databaseMoved) await _deleteFileBestEffort(rollbackDatabase);
      if (attachmentsMoved) {
        await _deleteDirectoryBestEffort(rollbackAttachments);
      }
      for (final pair in movedSidecars) {
        await _deleteFileBestEffort(pair.$2);
      }
    } catch (error) {
      if (switchValidated) rethrow;
      // Roll back files only after closing any standalone validation handle.
      if (stagedAttachmentsInstalled && await currentAttachments.exists()) {
        await currentAttachments.delete(recursive: true);
      }
      if (attachmentsMoved && await rollbackAttachments.exists()) {
        await rollbackAttachments.rename(currentAttachments.path);
      }
      if (stagedDatabaseInstalled && await databaseFile.exists()) {
        await databaseFile.delete();
      }
      if (databaseMoved && await rollbackDatabase.exists()) {
        await rollbackDatabase.rename(databaseFile.path);
      }
      for (final pair in movedSidecars.reversed) {
        if (await pair.$2.exists()) await pair.$2.rename(pair.$1.path);
      }
      if (error is BackupException) rethrow;
      throw const BackupException(
        '恢复未完成，原有数据已保留',
        code: BackupErrorCode.storage,
      );
    } finally {
      if (await stagedDatabase.exists()) await stagedDatabase.delete();
      if (await stagedAttachments.exists()) {
        await stagedAttachments.delete(recursive: true);
      }
      await cleanupPrepared(prepared);
    }
  }

  Future<void> cleanupCreated(CreatedBackup backup) {
    return _deleteDirectory(backup.workingDirectory);
  }

  Future<void> cleanupPrepared(PreparedRestore prepared) {
    return _deleteDirectory(Directory(prepared.workingDirectoryPath));
  }

  Future<void> _createDatabaseSnapshot(File destination) async {
    if (await destination.exists()) await destination.delete();
    final escaped = destination.path.replaceAll("'", "''");
    await _database.customStatement("VACUUM INTO '$escaped'");
    await _validateStandaloneDatabase(destination);
  }

  Future<void> _copyReferencedAttachment(
    String relativePath, {
    required Directory payload,
    required List<BackupFileRecord> records,
    String? expectedSha256,
  }) async {
    _validatePrivateRelativePath(relativePath);
    if (!relativePath.startsWith('diary/attachments/')) {
      throw const BackupException(
        '日记图片路径不在受保护目录中',
        code: BackupErrorCode.damaged,
      );
    }
    final support = await _paths.supportDirectory();
    final source = File(
      path.joinAll([support.path, ...relativePath.split('/')]),
    );
    if (!await source.exists()) {
      throw const BackupException(
        '有日记图片缺失，请先检查日记后重试',
        code: BackupErrorCode.missingFile,
      );
    }
    final archivePath = '$_filesPrefix$relativePath';
    final destination = File(
      path.joinAll([payload.path, ...archivePath.split('/')]),
    );
    await destination.parent.create(recursive: true);
    await source.copy(destination.path);
    final record = await _recordFor(destination, archivePath);
    if (expectedSha256 != null && record.sha256 != expectedSha256) {
      throw const BackupException(
        '日记原图校验失败，请重新保存该图片',
        code: BackupErrorCode.damaged,
      );
    }
    records.add(record);
  }

  Future<void> _createZip(
    Directory payload,
    File destination,
    List<BackupFileRecord> records,
  ) async {
    final encoder = ZipFileEncoder();
    encoder.create(destination.path);
    try {
      await encoder.addFile(
        File(path.join(payload.path, _manifestArchivePath)),
        _manifestArchivePath,
      );
      for (final record in records) {
        await encoder.addFile(
          File(path.joinAll([payload.path, ...record.path.split('/')])),
          record.path,
        );
      }
      await encoder.close();
    } catch (_) {
      try {
        await encoder.close();
      } catch (_) {
        // Preserve the original archive error.
      }
      rethrow;
    }
  }

  Future<void> _extractStrict(File zip, Directory destination) async {
    final stream = InputFileStream(zip.path);
    late Archive archive;
    try {
      archive = ZipDecoder().decodeStream(stream);
      if (archive.length > _maximumArchiveEntries) {
        throw const BackupException('备份包含过多文件', code: BackupErrorCode.damaged);
      }
      final seen = <String>{};
      var totalSize = 0;
      for (final entry in archive) {
        if (!entry.isFile || entry.isSymbolicLink) {
          throw const BackupException(
            '备份包含不支持的目录或链接',
            code: BackupErrorCode.damaged,
          );
        }
        final entryPath = entry.name;
        _validateArchivePath(entryPath);
        if (!seen.add(entryPath) ||
            entry.size < 0 ||
            entry.size > _maximumArchiveFileSize) {
          throw const BackupException(
            '备份文件记录异常',
            code: BackupErrorCode.damaged,
          );
        }
        totalSize += entry.size;
        if (totalSize > _maximumArchiveTotalSize) {
          throw const BackupException(
            '备份内容超过可恢复大小',
            code: BackupErrorCode.damaged,
          );
        }
        final output = File(
          path.joinAll([destination.path, ...entryPath.split('/')]),
        );
        await output.parent.create(recursive: true);
        final outputStream = OutputFileStream(output.path);
        try {
          entry.writeContent(outputStream);
          await outputStream.close();
        } catch (_) {
          await outputStream.close();
          throw const BackupException(
            '备份内容解压失败',
            code: BackupErrorCode.damaged,
          );
        }
        if (await output.length() != entry.size) {
          throw const BackupException(
            '备份内容大小校验失败',
            code: BackupErrorCode.damaged,
          );
        }
      }
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException('备份压缩内容已损坏', code: BackupErrorCode.damaged);
    } finally {
      await stream.close();
    }
  }

  Future<void> _verifyManifest(
    Directory extracted,
    BackupManifest manifest,
  ) async {
    final paths = manifest.files.map((record) => record.path).toSet();
    if (paths.length != manifest.files.length ||
        !paths.contains(_databaseArchivePath)) {
      throw const BackupException(
        '备份清单缺少数据库或包含重复文件',
        code: BackupErrorCode.damaged,
      );
    }
    final actualPaths = <String>{};
    await for (final entity in extracted.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        final relative = path
            .relative(entity.path, from: extracted.path)
            .replaceAll('\\', '/');
        if (relative != _manifestArchivePath) actualPaths.add(relative);
      }
    }
    if (actualPaths.length != paths.length || !actualPaths.containsAll(paths)) {
      throw const BackupException(
        '备份清单与实际文件不一致',
        code: BackupErrorCode.damaged,
      );
    }
    for (final record in manifest.files) {
      _validateArchivePath(record.path);
      final file = File(
        path.joinAll([extracted.path, ...record.path.split('/')]),
      );
      final actual = await _recordFor(file, record.path);
      if (actual.size != record.size || actual.sha256 != record.sha256) {
        throw const BackupException(
          '备份文件完整性校验失败',
          code: BackupErrorCode.damaged,
        );
      }
    }
  }

  Future<void> _validateDatabase(File file, BackupManifest manifest) async {
    final database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final check = await database.customSelect('PRAGMA quick_check').get();
      if (check.length != 1 || check.single.data.values.single != 'ok') {
        throw const BackupException(
          '备份数据库完整性检查失败',
          code: BackupErrorCode.damaged,
        );
      }
      final counts = await _readEntityCounts(database);
      for (final entry in manifest.entityCounts.entries) {
        if (counts[entry.key] != entry.value) {
          throw const BackupException(
            '备份数据库记录数量不一致',
            code: BackupErrorCode.damaged,
          );
        }
      }
      final attachments = await (database.select(
        database.diaryAttachments,
      )..where((table) => table.filesDeletedAt.isNull())).get();
      final referencedPaths = <String>{
        for (final attachment in attachments) ...[
          '$_filesPrefix${attachment.relativePath}',
          '$_filesPrefix${attachment.thumbnailRelativePath}',
        ],
      };
      final manifestAttachmentPaths = manifest.files
          .map((record) => record.path)
          .where((value) => value.startsWith(_filesPrefix))
          .toSet();
      if (referencedPaths.length != manifestAttachmentPaths.length ||
          !referencedPaths.containsAll(manifestAttachmentPaths)) {
        throw const BackupException(
          '备份图片清单与数据库引用不一致',
          code: BackupErrorCode.damaged,
        );
      }
    } finally {
      await database.close();
    }
  }

  Future<void> _validateStandaloneDatabase(File file) async {
    final database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final check = await database.customSelect('PRAGMA quick_check').get();
      if (check.length != 1 || check.single.data.values.single != 'ok') {
        throw const BackupException(
          '数据库完整性检查失败',
          code: BackupErrorCode.damaged,
        );
      }
    } finally {
      await database.close();
    }
  }

  Future<Map<String, int>> _readEntityCounts(AppDatabase database) async {
    final result = <String, int>{};
    for (final table in _entityTables) {
      final row = await database
          .customSelect('SELECT COUNT(*) AS count_value FROM $table')
          .getSingle();
      result[table] = row.read<int>('count_value');
    }
    return result;
  }

  Future<BackupFileRecord> _recordFor(File file, String archivePath) async {
    if (!await file.exists()) {
      throw const BackupException(
        '备份所需文件不存在',
        code: BackupErrorCode.missingFile,
      );
    }
    final digest = await sha256.bind(file.openRead()).first;
    return BackupFileRecord(
      path: archivePath,
      size: await file.length(),
      sha256: digest.toString(),
    );
  }

  void _validateArchivePath(String value) {
    _validatePrivateRelativePath(value);
    final allowed =
        value == _manifestArchivePath ||
        value == _databaseArchivePath ||
        value.startsWith('${_filesPrefix}diary/attachments/');
    if (!allowed) {
      throw const BackupException('备份包含未授权路径', code: BackupErrorCode.damaged);
    }
  }

  void _validatePrivateRelativePath(String value) {
    if (value.isEmpty ||
        value.contains('\\') ||
        path.posix.isAbsolute(value) ||
        path.posix.split(value).contains('..') ||
        path.posix.normalize(value) != value) {
      throw const BackupException('备份包含不安全路径', code: BackupErrorCode.damaged);
    }
  }

  Future<Directory> _createWorkingDirectory(String purpose) async {
    final temporary = await _paths.temporaryDirectory();
    await temporary.create(recursive: true);
    return Directory(
      path.join(temporary.path, 'lifeos_backup_${purpose}_${_uuid.v4()}'),
    )..createSync(recursive: true);
  }

  Future<void> _copyDirectory(
    Directory source,
    Directory destination, {
    bool allowMissingSource = false,
  }) async {
    await destination.create(recursive: true);
    if (!await source.exists()) {
      if (allowMissingSource) return;
      throw const BackupException(
        '恢复附件目录不存在',
        code: BackupErrorCode.missingFile,
      );
    }
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final relative = path.relative(entity.path, from: source.path);
      final target = File(path.join(destination.path, relative));
      await target.parent.create(recursive: true);
      await entity.copy(target.path);
    }
  }

  Future<void> _deleteDirectory(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> _deleteFileBestEffort(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // The committed database remains authoritative. A later maintenance
      // pass may remove a private rollback artifact that the OS kept busy.
    }
  }

  Future<void> _deleteDirectoryBestEffort(Directory directory) async {
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (_) {
      // See _deleteFileBestEffort.
    }
  }
}
