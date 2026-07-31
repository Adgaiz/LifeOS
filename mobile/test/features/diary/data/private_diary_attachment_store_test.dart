import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:lifeos/features/diary/data/private_diary_attachment_store.dart';

void main() {
  late Directory root;
  late PrivateDiaryAttachmentStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('lifeos_diary_test_');
    store = PrivateDiaryAttachmentStore(() async => root);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test(
    'creates private normalized master and thumbnail without touching source',
    () async {
      final source = File('${root.path}${Platform.pathSeparator}source.png');
      final sourceBytes = image_lib.encodePng(
        image_lib.Image(width: 3000, height: 1000)
          ..clear(image_lib.ColorRgb8(120, 80, 40)),
      );
      await source.writeAsBytes(sourceBytes);

      final staged = await store.stageImage(
        source.path,
        '00000000-0000-4000-8000-000000000036',
      );
      final masterPath = await store.resolveAbsolutePath(staged.relativePath);
      final thumbnailPath = await store.resolveAbsolutePath(
        staged.thumbnailRelativePath,
      );
      final masterBytes = await File(masterPath).readAsBytes();
      final master = image_lib.decodeJpg(masterBytes)!;
      final thumbnail = image_lib.decodeJpg(
        await File(thumbnailPath).readAsBytes(),
      )!;

      expect(await source.readAsBytes(), sourceBytes);
      expect(master.width, 2048);
      expect(master.height, lessThanOrEqualTo(2048));
      expect(thumbnail.width, 480);
      expect(thumbnail.height, lessThanOrEqualTo(480));
      expect(staged.checksumSha256, sha256.convert(masterBytes).toString());
      expect(staged.mediaType, 'image/jpeg');

      final promoted = await store.promoteImage(staged);
      expect(promoted.relativePath, contains('diary/attachments/'));
      expect(
        await File(
          await store.resolveAbsolutePath(promoted.relativePath),
        ).exists(),
        isTrue,
      );
      await store.discardStagedImage(staged);
      expect(await File(masterPath).exists(), isFalse);
    },
  );

  test('rejects paths that escape the private root', () async {
    await expectLater(
      store.resolveAbsolutePath('../outside.jpg'),
      throwsArgumentError,
    );
  });
}
