import 'dart:convert';

import 'package:lifeos/features/backup/domain/backup_exception.dart';

const lifeOsBackupFormatVersion = 1;

final class BackupFileRecord {
  const BackupFileRecord({
    required this.path,
    required this.size,
    required this.sha256,
  });

  factory BackupFileRecord.fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const BackupException(
        '备份清单格式无效',
        code: BackupErrorCode.invalidFormat,
      );
    }
    final path = value['path'];
    final size = value['size'];
    final sha256 = value['sha256'];
    if (path is! String ||
        path.isEmpty ||
        size is! int ||
        size < 0 ||
        sha256 is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256)) {
      throw const BackupException(
        '备份清单文件记录无效',
        code: BackupErrorCode.invalidFormat,
      );
    }
    return BackupFileRecord(path: path, size: size, sha256: sha256);
  }

  final String path;
  final int size;
  final String sha256;

  Map<String, Object?> toJson() => {
    'path': path,
    'size': size,
    'sha256': sha256,
  };
}

final class BackupManifest {
  const BackupManifest({
    required this.createdAt,
    required this.schemaVersion,
    required this.entityCounts,
    required this.files,
  });

  factory BackupManifest.fromJsonBytes(List<int> bytes) {
    try {
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, Object?> ||
          value['formatVersion'] != lifeOsBackupFormatVersion ||
          value['createdAt'] is! String ||
          value['schemaVersion'] is! int ||
          value['entityCounts'] is! Map<String, Object?> ||
          value['files'] is! List<Object?>) {
        throw const BackupException(
          '备份清单格式无效',
          code: BackupErrorCode.invalidFormat,
        );
      }
      final createdAt = DateTime.tryParse(value['createdAt'] as String);
      final schemaVersion = value['schemaVersion'] as int;
      if (createdAt == null || schemaVersion < 1) {
        throw const BackupException(
          '备份清单版本无效',
          code: BackupErrorCode.invalidFormat,
        );
      }
      final counts = <String, int>{};
      for (final entry
          in (value['entityCounts']! as Map<String, Object?>).entries) {
        if (entry.value is! int || (entry.value! as int) < 0) {
          throw const BackupException(
            '备份清单数量无效',
            code: BackupErrorCode.invalidFormat,
          );
        }
        counts[entry.key] = entry.value! as int;
      }
      return BackupManifest(
        createdAt: createdAt.toUtc(),
        schemaVersion: schemaVersion,
        entityCounts: counts,
        files: (value['files']! as List<Object?>)
            .map(BackupFileRecord.fromJson)
            .toList(growable: false),
      );
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException(
        '备份清单无法读取',
        code: BackupErrorCode.invalidFormat,
      );
    }
  }

  final DateTime createdAt;
  final int schemaVersion;
  final Map<String, int> entityCounts;
  final List<BackupFileRecord> files;

  List<int> toJsonBytes() => utf8.encode(
    jsonEncode({
      'formatVersion': lifeOsBackupFormatVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'schemaVersion': schemaVersion,
      'entityCounts': entityCounts,
      'files': files.map((file) => file.toJson()).toList(growable: false),
    }),
  );
}

final class BackupSummary {
  const BackupSummary({
    required this.createdAt,
    required this.fileSize,
    required this.attachmentCount,
  });

  final DateTime createdAt;
  final int fileSize;
  final int attachmentCount;
}

final class PreparedRestore {
  const PreparedRestore({
    required this.workingDirectoryPath,
    required this.databasePath,
    required this.attachmentsDirectoryPath,
    required this.manifest,
  });

  final String workingDirectoryPath;
  final String databasePath;
  final String attachmentsDirectoryPath;
  final BackupManifest manifest;
}

String? validateBackupPassword(String password) {
  if (password.trim().length < 10) {
    return '备份口令至少需要 10 个字符';
  }
  if (password.length > 128) {
    return '备份口令不能超过 128 个字符';
  }
  return null;
}
