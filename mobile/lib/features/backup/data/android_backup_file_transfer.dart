import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lifeos/features/backup/domain/backup_exception.dart';
import 'package:lifeos/features/backup/domain/backup_file_transfer.dart';

final class AndroidBackupFileTransfer implements BackupFileTransfer {
  const AndroidBackupFileTransfer({
    this.channel = const MethodChannel('com.adgaiz.lifeos/backup'),
  });

  final MethodChannel channel;

  @override
  Future<bool> exportBackup(File source, String suggestedName) async {
    try {
      return await channel.invokeMethod<bool>('exportBackup', {
            'sourcePath': source.path,
            'suggestedName': suggestedName,
          }) ??
          false;
    } on PlatformException {
      throw const BackupException(
        '无法保存备份文件，请检查存储空间后重试',
        code: BackupErrorCode.storage,
      );
    }
  }

  @override
  Future<File?> importBackup() async {
    try {
      final path = await channel.invokeMethod<String>('importBackup');
      return path == null ? null : File(path);
    } on PlatformException {
      throw const BackupException('无法读取所选备份文件', code: BackupErrorCode.storage);
    }
  }
}
