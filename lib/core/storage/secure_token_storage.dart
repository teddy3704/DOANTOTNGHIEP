import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureTokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class FlutterSecureTokenStorage implements SecureTokenStorage {
  FlutterSecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'moodle_access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('Token cannot be empty.');
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> delete() => _storage.delete(key: _tokenKey);
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  (ref) => FlutterSecureTokenStorage(),
);
