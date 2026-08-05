import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/features/ai/application/ai_providers.dart';
import 'package:lifeos/features/ai_companion/friend/application/ai_friend_service.dart';
import 'package:lifeos/features/ai_companion/friend/data/drift_ai_friend_repository.dart';
import 'package:lifeos/features/ai_companion/friend/domain/ai_friend_repository.dart';

final aiFriendRepositoryProvider = Provider<AiFriendRepository>((ref) {
  return DriftAiFriendRepository(ref.watch(appDatabaseProvider));
});

final aiFriendServiceProvider = Provider<AiFriendService>((ref) {
  return AiFriendService(
    ref.watch(aiFriendRepositoryProvider),
    ref.watch(aiServiceProvider),
  );
});
