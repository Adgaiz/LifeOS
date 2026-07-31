import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/vision/application/vision_service.dart';
import 'package:lifeos/features/vision/domain/vision.dart';
import 'package:lifeos/features/vision/domain/vision_repository.dart';

void main() {
  late _MemoryVisionRepository repository;
  late VisionService service;

  setUp(() {
    repository = _MemoryVisionRepository();
    service = VisionService(
      repository,
      now: () => DateTime.utc(2026, 7, 31, 8),
    );
  });

  test('creates and normalizes a vision', () async {
    await service.save(
      const VisionInput(title: '  30 岁的我  ', content: '  保持健康，也保持对生活的热情。  '),
    );

    final vision = repository.items.single;
    expect(vision.title, '30 岁的我');
    expect(vision.content, '保持健康，也保持对生活的热情。');
    expect(vision.status, VisionStatus.active);
    expect(vision.version, 1);
  });

  test('updates content while preserving identity and status', () async {
    final existing = Vision(
      id: '00000000-0000-4000-8000-000000000010',
      title: '未来的我',
      content: '持续学习',
      status: VisionStatus.archived,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      version: 2,
    );
    repository.items.add(existing);

    await service.save(
      VisionInput(id: existing.id, title: '未来的我', content: '持续学习，也认真生活'),
    );

    final updated = repository.items.single;
    expect(updated.id, existing.id);
    expect(updated.status, VisionStatus.archived);
    expect(updated.version, 3);
    expect(updated.content, '持续学习，也认真生活');
  });

  test('rejects an empty vision', () {
    expect(
      () => service.save(const VisionInput(title: ' ', content: ' ')),
      throwsA(isA<VisionValidationException>()),
    );
  });
}

final class _MemoryVisionRepository implements VisionRepository {
  final List<Vision> items = [];

  @override
  Future<Vision?> findById(String id) async {
    return items.where((vision) => vision.id == id).firstOrNull;
  }

  @override
  Future<void> save(Vision vision) async {
    items.removeWhere((item) => item.id == vision.id);
    items.add(vision);
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    items.removeWhere((vision) => vision.id == id);
  }

  @override
  Future<void> updateStatus(
    String id,
    VisionStatus status,
    DateTime updatedAt,
  ) async {
    final index = items.indexWhere((vision) => vision.id == id);
    final current = items[index];
    items[index] = Vision(
      id: current.id,
      title: current.title,
      content: current.content,
      status: status,
      createdAt: current.createdAt,
      updatedAt: updatedAt,
      version: current.version + 1,
    );
  }

  @override
  Stream<List<Vision>> watchAll() => Stream.value(items);
}
