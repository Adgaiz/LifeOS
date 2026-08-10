import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/core/storage/local_data_paths.dart';
import 'package:lifeos/features/backup/data/encrypted_backup_codec.dart';
import 'package:lifeos/features/backup/data/local_backup_data_source.dart';
import 'package:lifeos/features/backup/domain/backup_exception.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/diary/data/drift_diary_repository.dart';
import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory root;
  late _TestPaths paths;
  late AppDatabase database;
  late LocalBackupDataSource dataSource;
  late EncryptedBackupCodec codec;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('lifeos_backup_source_');
    paths = _TestPaths(root);
    await paths.create();
    database = AppDatabase.forTesting(
      NativeDatabase(await paths.databaseFile()),
    );
    codec = EncryptedBackupCodec(
      kdfParameters: const BackupKdfParameters(memoryKiB: 32, iterations: 1),
      chunkSize: 4096,
    );
    dataSource = LocalBackupDataSource(
      database: database,
      paths: paths,
      codec: codec,
    );
  });

  tearDown(() async {
    try {
      await database.close();
    } catch (_) {
      // commitRestore closes the injected connection itself.
    }
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'backs up referenced attachments and atomically restores database and files',
    () async {
      final masterBytes = List<int>.generate(7000, (index) => index % 211);
      final thumbnailBytes = List<int>.generate(800, (index) => index % 127);
      await _seedDiary(database, paths, masterBytes, thumbnailBytes);
      final orphan = File(
        path.join(
          (await paths.supportDirectory()).path,
          'diary',
          'attachments',
          'orphan.jpg',
        ),
      );
      await orphan.writeAsBytes([9, 9, 9]);

      final created = await dataSource.create('long test password');
      final prepared = await dataSource.prepareRestore(
        created.file,
        'long test password',
      );

      expect(
        prepared.manifest.files.map((record) => record.path),
        containsAll([
          'database/lifeos.sqlite',
          'files/diary/attachments/photo.jpg',
          'files/diary/attachments/photo_thumbnail.jpg',
        ]),
      );
      expect(
        prepared.manifest.files.any((record) => record.path.contains('orphan')),
        isFalse,
      );

      await database.customStatement(
        "UPDATE diary_entries SET markdown = 'changed after backup'",
      );
      final master = File(
        path.join(
          (await paths.supportDirectory()).path,
          'diary',
          'attachments',
          'photo.jpg',
        ),
      );
      await master.writeAsBytes([1, 2, 3]);

      await dataSource.commitRestore(prepared);

      final restored = AppDatabase.forTesting(
        NativeDatabase(await paths.databaseFile()),
      );
      try {
        final entry = await restored.select(restored.diaryEntries).getSingle();
        expect(entry.markdown, '# original');
        expect(await master.readAsBytes(), masterBytes);
        expect(await orphan.exists(), isFalse);
      } finally {
        await restored.close();
        await dataSource.cleanupCreated(created);
      }
    },
  );

  test(
    'rejects archive path traversal before touching the current database',
    () async {
      await database.customStatement('''
      INSERT INTO app_metadata (metadata_key, metadata_value, updated_at)
      VALUES ('sentinel', 'preserved', 0)
    ''');
      final zip = File(path.join(root.path, 'malicious.zip'));
      final encoder = ZipFileEncoder()..create(zip.path);
      encoder.addArchiveFile(ArchiveFile.string('../escape.txt', 'bad'));
      await encoder.close();
      final encrypted = File(path.join(root.path, 'malicious.lifeos-backup'));
      await codec.encrypt(
        input: zip,
        output: encrypted,
        password: 'long test password',
      );

      await expectLater(
        dataSource.prepareRestore(encrypted, 'long test password'),
        throwsA(
          isA<BackupException>().having(
            (error) => error.code,
            'code',
            BackupErrorCode.damaged,
          ),
        ),
      );
      final sentinel = await database
          .customSelect(
            "SELECT metadata_value FROM app_metadata WHERE metadata_key = 'sentinel'",
          )
          .getSingle();
      expect(sentinel.read<String>('metadata_value'), 'preserved');
      expect(await File(path.join(root.path, 'escape.txt')).exists(), isFalse);
    },
  );
}

Future<void> _seedDiary(
  AppDatabase database,
  LocalDataPaths paths,
  List<int> masterBytes,
  List<int> thumbnailBytes,
) async {
  final support = await paths.supportDirectory();
  final attachments = Directory(
    path.join(support.path, 'diary', 'attachments'),
  );
  await attachments.create(recursive: true);
  await File(
    path.join(attachments.path, 'photo.jpg'),
  ).writeAsBytes(masterBytes);
  await File(
    path.join(attachments.path, 'photo_thumbnail.jpg'),
  ).writeAsBytes(thumbnailBytes);
  final now = DateTime.utc(2026, 8, 6);
  await DriftDiaryRepository(database).save(
    DiaryAggregate(
      entry: DiaryEntry(
        id: '00000000-0000-4000-8000-000000000101',
        localDate: CalendarDate(2026, 8, 6),
        markdown: '# original',
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
      tags: const [],
      attachments: [
        DiaryAttachment(
          id: '00000000-0000-4000-8000-000000000102',
          diaryId: '00000000-0000-4000-8000-000000000101',
          relativePath: 'diary/attachments/photo.jpg',
          thumbnailRelativePath: 'diary/attachments/photo_thumbnail.jpg',
          mediaType: 'image/jpeg',
          sizeBytes: masterBytes.length,
          width: 100,
          height: 100,
          checksumSha256: sha256.convert(masterBytes).toString(),
          position: 0,
          createdAt: now,
          updatedAt: now,
          version: 1,
        ),
      ],
    ),
  );
}

final class _TestPaths implements LocalDataPaths {
  _TestPaths(this.root);

  final Directory root;

  Future<void> create() async {
    await (await documentsDirectory()).create(recursive: true);
    await (await supportDirectory()).create(recursive: true);
    await (await temporaryDirectory()).create(recursive: true);
  }

  @override
  Future<File> databaseFile() async {
    return File(path.join((await documentsDirectory()).path, 'lifeos.sqlite'));
  }

  @override
  Future<Directory> documentsDirectory() async =>
      Directory(path.join(root.path, 'documents'));

  @override
  Future<Directory> supportDirectory() async =>
      Directory(path.join(root.path, 'support'));

  @override
  Future<Directory> temporaryDirectory() async =>
      Directory(path.join(root.path, 'temporary'));
}
