import 'package:dio/dio.dart';

class AuthApi {
  final Dio dio;

  AuthApi(this.dio);

  Future<Response> login({required String email, required String password}) {
    return dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
  }

  Future<Response> register(Map<String, dynamic> data) {
    return dio.post('/auth/register', data: data);
  }

  Future<Response> forgotPassword(String email) {
    return dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<Response> resetPassword({
    required String token,
    required String password,
  }) {
    return dio.post(
      '/auth/reset-password',
      data: {'token': token, 'password': password},
    );
  }

  Future<Response> verifyEmail({required String userId, required String code}) {
    return dio.post(
      '/auth/verify-email',
      data: {'userId': userId, 'code': code},
    );
  }

  Future<Response> refreshToken(String refreshToken) {
    return dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
  }

  Future<Response> resendVerification(String email) {
    return dio.post('/auth/resend-verification', data: {'email': email});
  }

  // ─────────────────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────────────────

  Future<Response> getMe() {
    return dio.get('/users/me');
  }

  Future<Response> updateProfile(Map<String, dynamic> data) {
    return dio.patch('/users/me', data: data);
  }

  // ─────────────────────────────────────────────────────────
  // EMAIL CHANGE VERIFICATION
  // ─────────────────────────────────────────────────────────

  Future<Response> sendEmailChangeCode({required String email}) {
    return dio.post('/users/me/email/send-code', data: {'email': email});
  }

  Future<Response> verifyEmailChange({
    required String email,
    required String code,
  }) {
    return dio.post(
      '/users/me/email/verify',
      data: {'email': email, 'code': code},
    );
  }

  // ─────────────────────────────────────────────────────────
  // PASSWORD
  // ─────────────────────────────────────────────────────────

  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return dio.patch(
      '/users/me/password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  // ─────────────────────────────────────────────────────────
  // STRIPE / PAYOUTS
  // ─────────────────────────────────────────────────────────

  Future<Response> connectStripe() {
    return dio.get('/billing/stripe/connect');
  }

  // ─────────────────────────────────────────────────────────
  // PRIVACY / ACCOUNT DATA
  // ─────────────────────────────────────────────────────────

  Future<Response> exportMyData() {
    return dio.get(
      '/users/me/data-export',
      options: Options(responseType: ResponseType.json),
    );
  }

  Future<Response> deleteAccount({required String password, String? reason}) {
    return dio.delete(
      '/users/me',
      data: {
        'password': password,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // TWO-FACTOR AUTHENTICATION
  // ─────────────────────────────────────────────────────────

  Future<Response> setup2FA() {
    return dio.post('/auth/2fa/setup');
  }

  Future<Response> enable2FA(String totpCode) {
    return dio.post('/auth/2fa/enable', data: {'totpCode': totpCode});
  }

  Future<Response> verify2FA({
    required String userId,
    required String challengeToken,
    required String totpCode,
  }) {
    return dio.post(
      '/auth/2fa/verify',
      data: {
        'userId': userId,
        'challengeToken': challengeToken,
        'totpCode': totpCode,
      },
    );
  }

  Future<Response> disable2FA({
    required String totpCode,
    required String password,
  }) {
    return dio.patch(
      '/auth/2fa/disable',
      data: {'totpCode': totpCode, 'password': password},
    );
  }

  // ─────────────────────────────────────────────────────────
  // PUSH NOTIFICATIONS
  // ─────────────────────────────────────────────────────────

  Future<void> updateFcmToken(String token) async {
    await dio.patch('/users/me', data: {'fcmToken': token});
  }
}
