import 'package:lifeos/features/ai_companion/friend/domain/ai_friend.dart';

abstract interface class AiFriendRepository {
  Future<AiFriendExchange?> findLatest();

  Future<void> save(AiFriendExchange exchange);

  Future<void> delete(String id);
}
