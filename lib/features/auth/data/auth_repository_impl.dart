import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_api.dart';
import 'auth_repository.dart';
import 'models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi api;
  final AppCache _cache;
  AuthRepositoryImpl(this.api,this._cache);

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await api.login(email: email, password: password);
    final responseData = response.data['data'];

    if (responseData['requires2FA'] == true) {
      throw TwoFactorRequiredException(
        userId: responseData['userId'],
        challengeToken: responseData['challengeToken'],
      );
    }

    await AppStorage.saveAccessToken(responseData['accessToken']);
    await AppStorage.saveRefreshToken(responseData['refreshToken']);

    final user = UserModel.fromJson(responseData['user']);
    _cache.set(CacheKeys.me, user, CacheTtl.me);
    return user;
  }


  @override
  Future<UserModel> register(Map<String, dynamic> payload) async {
    final response = await api.register(payload);
    return UserModel.fromJson(response.data['data']);
  }

  @override
  Future<void> forgotPassword(String email) => api.forgotPassword(email);

  @override
  Future<void> verifyEmail({required String userId, required String code}) =>
      api.verifyEmail(userId: userId, code: code);

  @override
  Future<void> refreshSession() async {
    final token = await AppStorage.getRefreshToken();
    if (token == null) throw Exception('No refresh token');
    final response = await api.refreshToken(token);
    final data = response.data['data'];
    await AppStorage.saveAccessToken(data['accessToken']);
    await AppStorage.saveRefreshToken(data['refreshToken']);
  }

  @override
  Future<void> resendVerification({required String email}) =>
      api.resendVerification(email);

  // Profile ─────────────────────────────────────────────────

  @override
  Future<UserModel> getMe() async {
    final response = await api.getMe();
    return UserModel.fromJson(response.data['data']);
  }

  // @override
  // Future<UserModel> getMe() async {
  //   final cached = _cache.get<UserModel>(CacheKeys.me);
  //   if (cached != null && !cached.isExpired) return cached.data;
  //   final response = await api.getMe();
  //   final user = UserModel.fromJson(response.data['data']);
  //   _cache.set(CacheKeys.me, user, CacheTtl.me);
  //   return user;
  // }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await api.updateProfile(data);
    _cache.invalidate(CacheKeys.me); // force re-fetch after mutation
  }

  @override
  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) =>
      api.changePassword(
          currentPassword: currentPassword, newPassword: newPassword);

  @override
  Future<Map<String, dynamic>?> connectStripe() async {
    try {
      final response = await api.connectStripe();
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteAccount({required String password, String? reason}) async {
    final response = await api.deleteAccount(password: password, reason: reason);
    return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
  }

  // 2FA ─────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> setup2FA() async {
    final response = await api.setup2FA();
    return Map<String, dynamic>.from(response.data['data']);
  }

  @override
  Future<void> enable2FA(String totpCode) => api.enable2FA(totpCode);


  @override
  Future<UserModel> verify2FA({
    required String userId,
    required String challengeToken,
    required String totpCode,
  }) async {
    final response = await api.verify2FA(
      userId: userId,
      challengeToken: challengeToken,
      totpCode: totpCode,
    );
    final data = response.data['data'];
    await AppStorage.saveAccessToken(data['accessToken']);
    await AppStorage.saveRefreshToken(data['refreshToken']);
    final user = UserModel.fromJson(data['user']);
    _cache.set(CacheKeys.me, user, CacheTtl.me);
    return user;
  }

  @override
  Future<void> disable2FA(
      {required String totpCode, required String password}) async {
    await api.disable2FA(totpCode: totpCode, password: password);
    _cache.invalidate(CacheKeys.me);
  }

  @override
  Future<void> updateFcmToken(String token) async {
    await api.updateFcmToken(token);
  }
}

/// Thrown by login() when the backend requires a TOTP challenge.
/// The notifier catches this and transitions to the 2FA pending state.
class TwoFactorRequiredException implements Exception {
  final String userId;
  final String challengeToken;
  const TwoFactorRequiredException(
      {required this.userId, required this.challengeToken});
}