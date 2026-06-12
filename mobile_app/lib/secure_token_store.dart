import 'package:commerce_sdk/commerce_sdk.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'commerce_access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);
}
