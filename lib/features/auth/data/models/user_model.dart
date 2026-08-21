class CredentialSummary {
  final String type;
  final String status;
  final DateTime? expiresAt;

  const CredentialSummary({
    required this.type,
    required this.status,
    this.expiresAt,
  });

  factory CredentialSummary.fromJson(Map<String, dynamic> json) =>
      CredentialSummary(
        type: json['type'],
        status: json['status'],
        expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      );

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isExpiringSoon =>
      expiresAt != null &&
          !isExpired &&
          expiresAt!.isBefore(DateTime.now().add(const Duration(days: 30)));
}

class WalletSummary {
  final String id;
  final double pendingBalance;
  final double availableBalance;
  final double lifetimeEarnings;

  const WalletSummary({
    required this.id,
    required this.pendingBalance,
    required this.availableBalance,
    required this.lifetimeEarnings,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) => WalletSummary(
    id: json['id'],
    pendingBalance: double.tryParse(json['pendingBalance'].toString()) ?? 0,
    availableBalance: double.tryParse(json['availableBalance'].toString()) ?? 0,
    lifetimeEarnings: double.tryParse(json['lifetimeEarnings'].toString()) ?? 0,
  );
}

class NurseProfileData {
  final String id;
  final String firstName;
  final String lastName;
  final String designation;
  final String? avatarUrl;
  final String? bio;
  final int? yearsOfExperience;
  final double? availabilityRadius;
  final bool isAvailable;
  final String? city;
  final String? state;
  final String? stripeAccountId;
  final List<CredentialSummary> credentials;
  final WalletSummary? wallet;

  const NurseProfileData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.designation,
    this.avatarUrl,
    this.bio,
    this.yearsOfExperience,
    this.availabilityRadius,
    required this.isAvailable,
    this.city,
    this.state,
    this.stripeAccountId,
    required this.credentials,
    this.wallet,
  });

  factory NurseProfileData.fromJson(Map<String, dynamic> json) =>
      NurseProfileData(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        designation: json['designation'],
        avatarUrl: json['avatarUrl']?.toString(),
        bio: json['bio'],
        yearsOfExperience: json['yearsOfExperience'],
        availabilityRadius: (json['availabilityRadius'] as num?)?.toDouble(),
        isAvailable: json['isAvailable'] ?? true,
        city: json['city'],
        state: json['state'],
        stripeAccountId: json['stripeAccountId'],
        credentials: (json['credentials'] as List? ?? [])
            .map((c) => CredentialSummary.fromJson(c))
            .toList(),
        wallet: json['wallet'] != null
            ? WalletSummary.fromJson(json['wallet'])
            : null,
      );

  String get fullName => '$firstName $lastName';
}

class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String verificationStatus;
  final bool twoFactorEnabled;
  final DateTime? lastLoginAt;
  final NurseProfileData? nurseProfile;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.verificationStatus,
    required this.twoFactorEnabled,
    this.lastLoginAt,
    this.nurseProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    email: json['email'],
    phone: json['phone'],
    role: json['role'],
    status: json['status'] ?? 'PENDING',
    verificationStatus: json['verificationStatus'] ?? 'UNVERIFIED',
    twoFactorEnabled: json['twoFactorEnabled'] ?? false,
    lastLoginAt: json['lastLoginAt'] != null
        ? DateTime.parse(json['lastLoginAt'])
        : null,
    nurseProfile: json['nurseProfile'] != null
        ? NurseProfileData.fromJson(json['nurseProfile'])
        : null,
  );

  // Convenience getters
  String get displayName =>
      nurseProfile?.fullName ?? email.split('@').first;

  String get avatarUrl => nurseProfile?.avatarUrl ?? '';

  bool get isNurse => role == 'NURSE';
  bool get isVerified => verificationStatus == 'VERIFIED';
}