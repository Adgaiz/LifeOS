import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/backup/data/encrypted_backup_codec.dart';
import 'package:lifeos/features/backup/domain/backup_exception.dart';

void main() {
  late Directory root;
  late EncryptedBackupCodec codec;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('lifeos_backup_codec_');
    codec = EncryptedBackupCodec(
      kdfParameters: const BackupKdfParameters(memoryKiB: 32, iterations: 1),
      chunkSize: 4096,
      random: Random(42),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'round trips a payload spanning multiple authenticated chunks',
    () async {
      final source = File('${root.path}/payload.zip');
      final encrypted = File('${root.path}/backup.lifeos-backup');
      final restored = File('${root.path}/restored.zip');
      final bytes = List<int>.generate(10000, (index) => index % 251);
      await source.writeAsBytes(bytes);

      await codec.encrypt(
        input: source,
        output: encrypted,
        password: 'correct horse',
      );
      await codec.decrypt(
        input: encrypted,
        output: restored,
        password: 'correct horse',
      );

      expect(await restored.readAsBytes(), bytes);
    },
  );

  test('rejects an incorrect password without leaving clear text', () async {
    final source = File('${root.path}/payload.zip');
    final encrypted = File('${root.path}/backup.lifeos-backup');
    final restored = File('${root.path}/restored.zip');
    await source.writeAsBytes(List<int>.generate(6000, (index) => index % 256));
    await codec.encrypt(
      input: source,
      output: encrypted,
      password: 'right password',
    );

    await expectLater(
      codec.decrypt(
        input: encrypted,
        output: restored,
        password: 'wrong password',
      ),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          BackupErrorCode.invalidPassword,
        ),
      ),
    );
    expect(await restored.exists(), isFalse);
  });

  test('rejects tampering, truncation, and appended data', () async {
    final source = File('${root.path}/payload.zip');
    final original = File('${root.path}/backup.lifeos-backup');
    await source.writeAsBytes(List<int>.generate(9000, (index) => index % 199));
    await codec.encrypt(
      input: source,
      output: original,
      password: 'right password',
    );
    final bytes = await original.readAsBytes();

    final variants = <String, List<int>>{
      'tampered': [...bytes]..[bytes.length ~/ 2] ^= 1,
      'truncated': bytes.sublist(0, bytes.length - 1),
      'appended': [...bytes, 1],
    };
    for (final variant in variants.entries) {
      final encrypted = File('${root.path}/${variant.key}.lifeos-backup');
      final restored = File('${root.path}/${variant.key}.zip');
      await encrypted.writeAsBytes(variant.value);

      await expectLater(
        codec.decrypt(
          input: encrypted,
          output: restored,
          password: 'right password',
        ),
        throwsA(isA<BackupException>()),
        reason: variant.key,
      );
      expect(await restored.exists(), isFalse, reason: variant.key);
    }
  });
}
