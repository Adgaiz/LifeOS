import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/security/secure_store.dart';

final secureStoreProvider = Provider<SecureStore>((ref) {
  return AndroidSecureStore();
});
