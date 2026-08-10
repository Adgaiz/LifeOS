import 'package:lifeos/features/backup/data/local_backup_data_source.dart';
import 'package:lifeos/features/backup/domain/backup_exception.dart';
import 'package:lifeos/features/backup/domain/backup_file_transfer.dart';
import 'package:lifeos/features/backup/domain/backup_models.dart';

final class BackupService {
  BackupService(this._dataSource, this._fileTransfer);

  final LocalBackupDataSource _dataSource;
  final BackupFileTransfer _fileTransfer;
  bool _busy = false;

  Future<BackupSummary?> createBackup(String password) {
    return _guard(() async {
      final validation = validateBackupPassword(password);
      if (validation != null) {
        throw BackupException(
          validation,
          code: BackupErrorCode.invalidPassword,
        );
      }
      final backup = await _dataSource.create(password);
      try {
        final date = backup.summary.createdAt.toLocal();
        final name =
            'LifeOS-${date.year.toString().padLeft(4, '0')}'
            '${date.month.toString().padLeft(2, '0')}'
            '${date.day.toString().padLeft(2, '0')}.lifeos-backup';
        final saved = await _fileTransfer.exportBackup(backup.file, name);
        return saved ? backup.summary : null;
      } finally {
        await _dataSource.cleanupCreated(backup);
      }
    });
  }

  Future<PreparedRestore?> prepareRestore(String password) {
    return _guard(() async {
      if (password.isEmpty) {
        throw const BackupException(
          '请输入创建备份时使用的口令',
          code: BackupErrorCode.invalidPassword,
        );
      }
      final imported = await _fileTransfer.importBackup();
      if (imported == null) return null;
      try {
        return await _dataSource.prepareRestore(imported, password);
      } finally {
        if (await imported.exists()) await imported.delete();
      }
    });
  }

  Future<void> confirmRestore(PreparedRestore prepared) {
    return _guard(() => _dataSource.commitRestore(prepared));
  }

  Future<void> cancelRestore(PreparedRestore prepared) {
    return _dataSource.cleanupPrepared(prepared);
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    if (_busy) {
      throw const BackupException('已有备份或恢复任务正在进行', code: BackupErrorCode.busy);
    }
    _busy = true;
    try {
      return await operation();
    } finally {
      _busy = false;
    }
  }
}
