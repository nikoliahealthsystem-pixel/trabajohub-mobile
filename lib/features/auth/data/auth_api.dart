import 'package:dio/dio.dart';

class AuthApi {
  final Dio dio;

  AuthApi(this.dio);

  Future<Response> login({
    required String email,
    required String password,
  }) {
    return dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> register(Map<String, dynamic> data) {
    return dio.post('/auth/register', data: data);
  }

  Future<Response> forgotPassword(String email) {
    return dio.post(
      '/auth/forgot-password',
      data: {
        'email': email,
      },
    );
  }

  Future<Response> resetPassword({
    required String token,
    required String password,
  }) {
    return dio.post(
      '/auth/reset-password',
      data: {
        'token': token,
        'password': password,
      },
    );
  }

  Future<Response> verifyEmail({
    required String userId,
    required String code,
  }) {
    return dio.post(
      '/auth/verify-email',
      data: {
        'userId': userId,
        'code': code,
      },
    );
  }

  Future<Response> refreshToken(String refreshToken) {
    return dio.post(
      '/auth/refresh',
      data: {
        'refreshToken': refreshToken,
      },
    );
  }

  Future<Response> resendVerification(
      String email,
      ) {
    return dio.post(
      '/auth/resend-verification',
      data: {
        'email': email,
      },
    );
  }

  ///profile section
  Future<Response> getMe() => dio.get('/users/me');

  Future<Response> updateProfile(Map<String, dynamic> data) =>
      dio.patch('/users/me', data: data);

  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      dio.patch('/users/me/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
  Future<Response> connectStripe() => dio.get('/billing/stripe/connect');

  Future<Response> deleteAccount({
    required String password,
    String? reason,
  }) {
    return dio.delete(
      '/users/me',
      data: {
        'password': password,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  // ── 2FA ──────────────────────────────────────────────────

  /// GET the QR code + secret for first-time setup
  Future<Response> setup2FA() => dio.post('/auth/2fa/setup');

  /// Activate 2FA by confirming the first TOTP code
  Future<Response> enable2FA(String totpCode) =>
      dio.post('/auth/2fa/enable', data: {'totpCode': totpCode});

  /// Complete login when 2FA challenge is required
  Future<Response> verify2FA({
    required String userId,
    required String challengeToken,
    required String totpCode,
  }) =>
      dio.post('/auth/2fa/verify', data: {
        'userId': userId,
        'challengeToken': challengeToken,
        'totpCode': totpCode,
      });

  /// Disable 2FA — requires current password + TOTP
  Future<Response> disable2FA({
    required String totpCode,
    required String password,
  }) =>
      dio.patch('/auth/2fa/disable',
          data: {'totpCode': totpCode, 'password': password});

  Future<void> updateFcmToken(String token) async {
    await dio.patch(
      '/users/me',
      data: {'fcmToken': token},
    );
  }
}