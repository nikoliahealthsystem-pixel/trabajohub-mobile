import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/socket/socket_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../data/auth_repository_impl.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final SocketClient _socketClient;

  AuthNotifier(this.repository, this._socketClient) : super(const AuthState());

  // ── Login (handles 2FA challenge) ─────────────────────────

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await repository.login(email, password);
      if(!user.isNurse){
        state = state.copyWith(isLoading: false, error: "The App Isn't Accessible For ${user.role.replaceAll("_", " ")}");
        return false;
      }
      state = state.copyWith(isLoading: false, user: user);
      await _socketClient.connect();
      return true;
    } on TwoFactorRequiredException catch (e) {
      // Don't set error — this is an expected flow
      state = state.copyWith(
        isLoading: false,
        requires2FA: true,
        pendingUserId: e.userId,
        pendingChallengeToken: e.challengeToken,
      );
      return false; // caller checks state.requires2FA
    } catch (e) {
      String message = 'Something went wrong';

      if (e is DioException) {
        final data = e.response?.data;

        if (data is Map<String, dynamic>) {
          message = data['message']?.toString() ?? message;
        } else {
          message = e.message ?? message;
        }
      } else {
        message = e.toString();
      }

      state = state.copyWith(
        isLoading: false,
        error: message,
      );

      return false;
    }
  }

  // ── Complete 2FA login challenge ──────────────────────────

  Future<bool> verify2FA(String totpCode) async {
    final userId = state.pendingUserId;
    final challenge = state.pendingChallengeToken;
    if (userId == null || challenge == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await repository.verify2FA(
        userId: userId,
        challengeToken: challenge,
        totpCode: totpCode,
      );
      if(!user.isNurse){
        state = state.copyWith(isLoading: false, error: "The App Isn't Accessible For ${user.role.replaceAll("_", " ")}");
        return false;
      }
      if (user.isNurse) await _socketClient.connect();
      state = AuthState(user: user); // full reset — clears all pending state
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  void cancel2FAChallenge() {
    state = state.clearTwoFAPending();
  }

  // ── Setup 2FA (from profile settings) ────────────────────

  Future<bool> setup2FA() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await repository.setup2FA();
      state = state.copyWith(
        isLoading: false,
        twoFAQrCode: data['qrCodeUrl'] as String?,
        twoFASecret: data['secret'] as String?,
      );
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  /// Called after user scans QR and enters first code
  Future<bool> enable2FA(String totpCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.enable2FA(totpCode);
      // Re-fetch so user.twoFactorEnabled reflects the change
      await fetchMe();
      state = state.copyWith(
        twoFASetupSuccess: true,
        twoFAQrCode: null,
        twoFASecret: null,
      );
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  /// Called from profile settings to disable 2FA
  Future<bool> disable2FA({
    required String totpCode,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.disable2FA(totpCode: totpCode, password: password);
      await fetchMe();
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  // ── Existing methods ──────────────────────────────────────

  Future<void> initializeAuth() async {
    final token = await AppStorage.getAccessToken();
    if (token != null) {
      try {
        await fetchMe();
        await _socketClient.connect();
      } catch (_) {
        await logout();
        _socketClient.disconnect();
      }
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await repository.forgotPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<String?> register(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await repository.register(payload);
      state = state.copyWith(isLoading: false);
      return user.id;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return null;
    }
  }

  Future<bool> verifyEmail(String userId, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.verifyEmail(userId: userId, code: code);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<bool> resendVerification(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.resendVerification(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<void> logout() async {
    _socketClient.disconnect();
    await AppStorage.clear();
    state = const AuthState();
  }

  Future<void> fetchMe() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await repository.getMe();
      state = state.copyWith(isLoading: false, user: user);
      await _socketClient.connect();
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.updateProfile(data);
      await fetchMe();
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<bool> deleteAccount({
    required String password,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.deleteAccount(
        password: password,
        reason: reason,
      );
      await logout();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<Map<String, dynamic>?> connectStripe() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await repository.connectStripe();
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isLoading: false, error: message);
      return {'error': e.toString()};
    }
  }
  /// Update FCM token on the backend
  Future<bool> updateFcmToken(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.updateFcmToken(token);   // We'll add this in repository too
      await fetchMe(); // Refresh user data
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Failed to update notification settings')
          : e.toString();

      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }
}