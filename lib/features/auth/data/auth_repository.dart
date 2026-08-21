import 'models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(Map<String, dynamic> payload);
  Future<void> forgotPassword(String email);
  Future<void> verifyEmail({required String userId, required String code});
  Future<void> refreshSession();
  Future<void> resendVerification({required String email});

  ///Profile section
  Future<UserModel> getMe();
  Future<void> updateProfile(Map<String, dynamic> data);
  Future<void> changePassword({required String currentPassword, required String newPassword});
  Future<Map<String, dynamic>?> connectStripe();
  Future<Map<String, dynamic>> deleteAccount({required String password, String? reason});

  // ── 2FA ──────────────────────────────────────────────────

  /// Returns { secret, qrCodeUrl }
  Future<Map<String, dynamic>> setup2FA();

  /// Activates 2FA after user scans QR and enters first code
  Future<void> enable2FA(String totpCode);

  /// Called when login returns requires2FA=true
  /// Returns full UserModel (tokens saved internally)
  Future<UserModel> verify2FA({
    required String userId,
    required String challengeToken,
    required String totpCode,
  });

  Future<void> disable2FA({
    required String totpCode,
    required String password,
  });
  Future<void> updateFcmToken(String token);
}