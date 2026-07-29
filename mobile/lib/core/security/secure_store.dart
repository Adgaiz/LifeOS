import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureStore {
  Future<void> write({required String key, required String value});

  Future<String?> read({required String key});

  Future<void> delete({required String key});
}

final class AndroidSecureStore implements SecureStore {
  AndroidSecureStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              storageNamespace: 'lifeos.secrets',
              resetOnError: false,
              migrateWithBackup: true,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}
