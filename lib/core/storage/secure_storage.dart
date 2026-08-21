import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'accessToken', value: token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: 'refreshToken', value: token);
  }
  static Future<void> saveSessionId(String sessionId) async {
    await _storage.write(key: 'sessionId', value: sessionId);
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: 'accessToken');
  }
  static Future<String?> getRefreshToken() async {
    return _storage.read(key: 'refreshToken');
  }
  static Future<String?> getSessionId() async {
    return _storage.read(key: 'sessionId');
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}