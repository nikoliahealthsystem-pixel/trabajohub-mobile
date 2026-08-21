import '../data/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool profileUpdateSuccess;

  // ── 2FA login challenge ──────────────────────────────────
  /// Set when login returns requires2FA=true
  final bool requires2FA;
  final String? pendingUserId;
  final String? pendingChallengeToken;

  // ── 2FA setup ────────────────────────────────────────────
  /// QR code data URL from /auth/2fa/setup
  final String? twoFAQrCode;
  final String? twoFASecret;
  final bool twoFASetupSuccess;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.profileUpdateSuccess = false,
    this.requires2FA = false,
    this.pendingUserId,
    this.pendingChallengeToken,
    this.twoFAQrCode,
    this.twoFASecret,
    this.twoFASetupSuccess = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    bool? profileUpdateSuccess,
    bool? requires2FA,
    String? pendingUserId,
    String? pendingChallengeToken,
    String? twoFAQrCode,
    String? twoFASecret,
    bool? twoFASetupSuccess,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        user: user ?? this.user,
        profileUpdateSuccess: profileUpdateSuccess ?? false,
        requires2FA: requires2FA ?? this.requires2FA,
        pendingUserId: pendingUserId ?? this.pendingUserId,
        pendingChallengeToken:
        pendingChallengeToken ?? this.pendingChallengeToken,
        twoFAQrCode: twoFAQrCode ?? this.twoFAQrCode,
        twoFASecret: twoFASecret ?? this.twoFASecret,
        twoFASetupSuccess: twoFASetupSuccess ?? false,
      );

  /// Clear all 2FA pending state
  AuthState clearTwoFAPending() => copyWith(
    requires2FA: false,
    pendingUserId: null,
    pendingChallengeToken: null,
  );
}