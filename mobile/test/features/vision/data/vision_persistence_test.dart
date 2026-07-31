import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/features/vision/data/drift_vision_repository.dart';
import 'package:lifeos/features/vision/domain/vision.dart';

void main() {
  late AppDatabase database;
  late DriftVisionRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftVisionRepository(database);
  });

  tearDown(() => database.close());

  test('persists, archives and soft-deletes a vision', () async {
    final now = DateTime.utc(2026, 7, 31, 8);
    const id = '00000000-0000-4000-8000-000000000011';
    await repository.save(
      Vision(
        id: id,
        title: '理想生活',
        content: '身体健康，持续学习，珍惜关系。',
        status: VisionStatus.active,
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
    );

    await repository.updateStatus(
      id,
      VisionStatus.archived,
      now.add(const Duration(minutes: 1)),
    );
    final archived = await repository.findById(id);
    expect(archived?.status, VisionStatus.archived);
    expect(archived?.version, 2);

    await repository.softDelete(id, now.add(const Duration(minutes: 2)));
    expect(await repository.findById(id), isNull);
    expect(await repository.watchAll().first, isEmpty);
  });
}
