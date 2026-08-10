final class BackupException implements Exception {
  const BackupException(this.message, {this.code = BackupErrorCode.unknown});

  final String message;
  final BackupErrorCode code;

  @override
  String toString() => 'BackupException($code): $message';
}

enum BackupErrorCode {
  invalidPassword,
  invalidFormat,
  damaged,
  incompatible,
  missingFile,
  storage,
  busy,
  unknown,
}
