import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/core/storage/local_data_paths.dart';
import 'package:lifeos/features/backup/application/backup_service.dart';
import 'package:lifeos/features/backup/data/android_backup_file_transfer.dart';
import 'package:lifeos/features/backup/data/encrypted_backup_codec.dart';
import 'package:lifeos/features/backup/data/local_backup_data_source.dart';
import 'package:lifeos/features/backup/domain/backup_file_transfer.dart';

final localDataPathsProvider = Provider<LocalDataPaths>((ref) {
  return const PlatformLocalDataPaths();
});

final encryptedBackupCodecProvider = Provider<EncryptedBackupCodec>((ref) {
  return EncryptedBackupCodec();
});

final backupFileTransferProvider = Provider<BackupFileTransfer>((ref) {
  return const AndroidBackupFileTransfer();
});

final localBackupDataSourceProvider = Provider<LocalBackupDataSource>((ref) {
  return LocalBackupDataSource(
    database: ref.watch(appDatabaseProvider),
    paths: ref.watch(localDataPathsProvider),
    codec: ref.watch(encryptedBackupCodecProvider),
  );
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(localBackupDataSourceProvider),
    ref.watch(backupFileTransferProvider),
  );
});
