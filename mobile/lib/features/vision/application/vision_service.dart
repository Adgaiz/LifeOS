import 'package:lifeos/features/vision/domain/vision.dart';
import 'package:lifeos/features/vision/domain/vision_repository.dart';
import 'package:uuid/uuid.dart';

final class VisionService {
  VisionService(this._repository, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final VisionRepository _repository;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> save(VisionInput input) async {
    final normalized = input.validateAndNormalize();
    final existing = input.id == null
        ? null
        : await _repository.findById(input.id!);
    if (input.id != null && existing == null) {
      throw StateError('Vision not found: ${input.id}');
    }
    final now = _now().toUtc();
    await _repository.save(
      Vision(
        id: existing?.id ?? _uuid.v4(),
        title: normalized.title,
        content: normalized.content,
        status: existing?.status ?? VisionStatus.active,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        version: (existing?.version ?? 0) + 1,
      ),
    );
  }

  Future<void> archive(String id) {
    return _repository.updateStatus(id, VisionStatus.archived, _now().toUtc());
  }

  Future<void> restore(String id) {
    return _repository.updateStatus(id, VisionStatus.active, _now().toUtc());
  }

  Future<void> delete(String id) {
    return _repository.softDelete(id, _now().toUtc());
  }
}
