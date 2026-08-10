import 'dart:io';

abstract interface class BackupFileTransfer {
  /// Copies [source] to a user-selected location. Returns false on cancellation.
  Future<bool> exportBackup(File source, String suggestedName);

  /// Copies a user-selected backup into a private temporary file.
  Future<File?> importBackup();
}
