enum CredentialType {
  stateLicense,
  cprCertification,
  tbTest,
  backgroundCheck,
  governmentId,
  oigCheck,
  samCheck,
  immunization,
  workAuthorization,
  custom;

  static CredentialType fromString(String raw) {
    switch (raw) {
      case 'STATE_LICENSE':
        return stateLicense;
      case 'CPR_CERTIFICATION':
        return cprCertification;
      case 'TB_TEST':
        return tbTest;
      case 'BACKGROUND_CHECK':
        return backgroundCheck;
      case 'GOVERNMENT_ID':
        return governmentId;
      case 'OIG_CHECK':
        return oigCheck;
      case 'SAM_CHECK':
        return samCheck;
      case 'IMMUNIZATION':
        return immunization;
      case 'WORK_AUTHORIZATION':
        return workAuthorization;
      case 'CUSTOM':
        return custom;
      default:
        throw ArgumentError('Unknown credential type: $raw');
    }
  }

  String toApiString() {
    switch (this) {
      case stateLicense: return 'STATE_LICENSE';
      case cprCertification: return 'CPR_CERTIFICATION';
      case tbTest: return 'TB_TEST';
      case backgroundCheck: return 'BACKGROUND_CHECK';
      case governmentId: return 'GOVERNMENT_ID';
      case oigCheck: return 'OIG_CHECK';
      case samCheck: return 'SAM_CHECK';
      case immunization: return 'IMMUNIZATION';
      case workAuthorization: return 'WORK_AUTHORIZATION';
      case custom: return 'CUSTOM';
    }
  }

  String get label {
    switch (this) {
      case stateLicense: return 'State License';
      case cprCertification: return 'CPR Certification';
      case tbTest: return 'TB Test';
      case backgroundCheck: return 'Background Check';
      case governmentId: return 'Government ID';
      case oigCheck: return 'OIG Check';
      case samCheck: return 'SAM Check';
      case immunization: return 'Immunization';
      case workAuthorization: return 'Work Authorization';
      case custom: return 'Custom';
    }
  }
}

extension CredentialTypeX on CredentialType {
  String get apiValue => switch (this) {
    CredentialType.stateLicense => 'STATE_LICENSE',
    CredentialType.cprCertification => 'CPR_CERTIFICATION',
    CredentialType.tbTest => 'TB_TEST',
    CredentialType.backgroundCheck => 'BACKGROUND_CHECK',
    CredentialType.governmentId => 'GOVERNMENT_ID',
    CredentialType.oigCheck => 'OIG_CHECK',
    CredentialType.samCheck => 'SAM_CHECK',
    CredentialType.immunization => 'IMMUNIZATION',
    CredentialType.workAuthorization => 'WORK_AUTHORIZATION',
    CredentialType.custom => 'CUSTOM',
  };

  String get label => switch (this) {
    CredentialType.stateLicense => 'State License',
    CredentialType.cprCertification => 'CPR Certification',
    CredentialType.tbTest => 'TB Test',
    CredentialType.backgroundCheck => 'Background Check',
    CredentialType.governmentId => 'Government ID',
    CredentialType.oigCheck => 'OIG Check',
    CredentialType.samCheck => 'SAM Check',
    CredentialType.immunization => 'Immunization',
    CredentialType.workAuthorization => 'Work Authorization',
    CredentialType.custom => 'Custom',
  };
}

enum CredentialStatus {
  pending, approved, rejected, expired;

  static CredentialStatus fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'APPROVED': return approved;
      case 'REJECTED': return rejected;
      case 'EXPIRED': return expired;
      default: return pending;
    }
  }

  String get label => name[0].toUpperCase() + name.substring(1);
}

class CredentialModel {
  final String id;
  final String nurseProfileId;
  final CredentialType type;
  final String? customLabel;
  final String fileUrl;
  final String fileKey;
  final CredentialStatus status;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final String? rejectionReason;
  final String? downloadUrl;
  final DateTime createdAt;

  const CredentialModel({
    required this.id,
    required this.nurseProfileId,
    required this.type,
    this.customLabel,
    required this.fileUrl,
    required this.fileKey,
    required this.status,
    this.issuedAt,
    this.expiresAt,
    this.rejectionReason,
    this.downloadUrl,
    required this.createdAt,
  });

  factory CredentialModel.fromJson(Map<String, dynamic> json) =>
      CredentialModel(
        id: json['id'],
        nurseProfileId: json['nurseProfileId'],
        type: CredentialType.fromString(json['type'] ?? ''),
        customLabel: json['customLabel'],
        fileUrl: json['fileUrl'] ?? '',
        fileKey: json['fileKey'] ?? '',
        status: CredentialStatus.fromString(json['status'] ?? ''),
        issuedAt: json['issuedAt'] != null
            ? DateTime.parse(json['issuedAt'])
            : null,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'])
            : null,
        rejectionReason: json['rejectionReason'],
        downloadUrl: json['downloadUrl'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  String get displayLabel => customLabel ?? type.label;

  bool get isExpiringSoon =>
      expiresAt != null &&
          !isExpired &&
          expiresAt!.isBefore(DateTime.now().add(const Duration(days: 30)));

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get canDelete => status != CredentialStatus.approved;
}