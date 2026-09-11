import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _sessionIdKey = 'sessionId';

  static const _rememberMeKey = 'rememberMe';
  static const _rememberedEmailKey = 'rememberedEmail';

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<void> saveSessionId(String sessionId) async {
    await _storage.write(key: _sessionIdKey, value: sessionId);
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<String?> getSessionId() async {
    return _storage.read(key: _sessionIdKey);
  }

  static Future<void> setRememberMe({
    required bool remember,
    String? email,
  }) async {
    await _storage.write(
      key: _rememberMeKey,
      value: remember ? 'true' : 'false',
    );

    if (remember && email != null && email.trim().isNotEmpty) {
      await _storage.write(key: _rememberedEmailKey, value: email.trim());
    } else {
      await _storage.delete(key: _rememberedEmailKey);
    }
  }

  static Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);

    return value == 'true';
  }

  static Future<String?> getRememberedEmail() async {
    return _storage.read(key: _rememberedEmailKey);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);

    await _storage.delete(key: _refreshTokenKey);

    await _storage.delete(key: _sessionIdKey);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
