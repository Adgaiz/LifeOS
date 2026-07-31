import 'package:lifeos/features/vision/domain/vision.dart';

abstract interface class VisionRepository {
  Stream<List<Vision>> watchAll();

  Future<Vision?> findById(String id);

  Future<void> save(Vision vision);

  Future<void> updateStatus(String id, VisionStatus status, DateTime updatedAt);

  Future<void> softDelete(String id, DateTime deletedAt);
}
