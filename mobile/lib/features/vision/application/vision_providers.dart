import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/features/vision/application/vision_service.dart';
import 'package:lifeos/features/vision/data/drift_vision_repository.dart';
import 'package:lifeos/features/vision/domain/vision.dart';
import 'package:lifeos/features/vision/domain/vision_repository.dart';

final visionRepositoryProvider = Provider<VisionRepository>((ref) {
  return DriftVisionRepository(ref.watch(appDatabaseProvider));
});

final visionServiceProvider = Provider<VisionService>((ref) {
  return VisionService(ref.watch(visionRepositoryProvider));
});

final allVisionsProvider = StreamProvider.autoDispose<List<Vision>>((ref) {
  return ref.watch(visionRepositoryProvider).watchAll();
});
