import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _apiKeyKey = 'claude_api_key';

  final _storage = const FlutterSecureStorage();

  Future<void> saveApiKey(String apiKey) =>
      _storage.write(key: _apiKeyKey, value: apiKey);

  Future<String?> getApiKey() => _storage.read(key: _apiKeyKey);

  Future<void> deleteApiKey() => _storage.delete(key: _apiKeyKey);
}
