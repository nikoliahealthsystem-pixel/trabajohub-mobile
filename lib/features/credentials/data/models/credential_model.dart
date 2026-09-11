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

  static CredentialType fromString(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
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
        return custom;
    }
  }

  String get apiValue {
    switch (this) {
      case CredentialType.stateLicense:
        return 'STATE_LICENSE';
      case CredentialType.cprCertification:
        return 'CPR_CERTIFICATION';
      case CredentialType.tbTest:
        return 'TB_TEST';
      case CredentialType.backgroundCheck:
        return 'BACKGROUND_CHECK';
      case CredentialType.governmentId:
        return 'GOVERNMENT_ID';
      case CredentialType.oigCheck:
        return 'OIG_CHECK';
      case CredentialType.samCheck:
        return 'SAM_CHECK';
      case CredentialType.immunization:
        return 'IMMUNIZATION';
      case CredentialType.workAuthorization:
        return 'WORK_AUTHORIZATION';
      case CredentialType.custom:
        return 'CUSTOM';
    }
  }

  String toApiString() => apiValue;

  String get label {
    switch (this) {
      case CredentialType.stateLicense:
        return 'State License';
      case CredentialType.cprCertification:
        return 'CPR Certification';
      case CredentialType.tbTest:
        return 'TB Test';
      case CredentialType.backgroundCheck:
        return 'Background Check';
      case CredentialType.governmentId:
        return 'Government ID';
      case CredentialType.oigCheck:
        return 'OIG Check';
      case CredentialType.samCheck:
        return 'SAM Check';
      case CredentialType.immunization:
        return 'Immunization';
      case CredentialType.workAuthorization:
        return 'Work Authorization';
      case CredentialType.custom:
        return 'Custom';
    }
  }
}

enum CredentialStatus {
  pending,
  approved,
  rejected,
  expired;

  static CredentialStatus fromString(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'APPROVED':
        return approved;
      case 'REJECTED':
        return rejected;
      case 'EXPIRED':
        return expired;
      case 'PENDING':
      default:
        return pending;
    }
  }

  String get label {
    switch (this) {
      case CredentialStatus.pending:
        return 'Pending';
      case CredentialStatus.approved:
        return 'Approved';
      case CredentialStatus.rejected:
        return 'Rejected';
      case CredentialStatus.expired:
        return 'Expired';
    }
  }
}

class CredentialModel {
  final String id;
  final String nurseProfileId;
  final CredentialType type;
  final String? customLabel;

  /// Legacy/internal fields.
  ///
  /// Nurse-facing backend responses intentionally may not expose these.
  final String fileUrl;
  final String fileKey;

  final CredentialStatus status;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final String? rejectionReason;

  /// Signed/private nurse-facing URL returned by the backend.
  final String? downloadUrl;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;

  const CredentialModel({
    required this.id,
    required this.nurseProfileId,
    required this.type,
    this.customLabel,
    this.fileUrl = '',
    this.fileKey = '',
    required this.status,
    this.issuedAt,
    this.expiresAt,
    this.rejectionReason,
    this.downloadUrl,
    required this.createdAt,
    this.updatedAt,
    this.reviewedAt,
  });

  factory CredentialModel.fromJson(Map<String, dynamic> json) {
    return CredentialModel(
      id: json['id']?.toString() ?? '',
      nurseProfileId: json['nurseProfileId']?.toString() ?? '',
      type: CredentialType.fromString(json['type']?.toString()),
      customLabel: _nullableString(json['customLabel']),
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileKey: json['fileKey']?.toString() ?? '',
      status: CredentialStatus.fromString(json['status']?.toString()),
      issuedAt: _parseDate(json['issuedAt']),
      expiresAt: _parseDate(json['expiresAt']),
      rejectionReason: _nullableString(json['rejectionReason']),
      downloadUrl: _nullableString(json['downloadUrl']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      reviewedAt: _parseDate(json['reviewedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    return DateTime.tryParse(raw);
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return null;

    return raw;
  }

  String get displayLabel {
    if (type == CredentialType.custom &&
        customLabel != null &&
        customLabel!.trim().isNotEmpty) {
      return customLabel!.trim();
    }

    return type.label;
  }

  /// Prefer the backend's signed URL.
  String? get previewUrl {
    final signed = downloadUrl?.trim();

    if (signed != null && signed.isNotEmpty) {
      return signed;
    }

    final legacy = fileUrl.trim();

    if (legacy.isNotEmpty) {
      return legacy;
    }

    return null;
  }

  bool get hasPreviewUrl => previewUrl != null;

  /// Attempts to determine the document extension from either the signed
  /// URL or legacy URL without being confused by query parameters.
  String get fileExtension {
    final url = previewUrl;

    if (url == null || url.isEmpty) {
      return '';
    }

    try {
      final uri = Uri.parse(url);
      final path = uri.path;

      if (!path.contains('.')) {
        return '';
      }

      return path.split('.').last.toLowerCase();
    } catch (_) {
      final clean = url.split('?').first.split('#').first;

      if (!clean.contains('.')) {
        return '';
      }

      return clean.split('.').last.toLowerCase();
    }
  }

  bool get isImage {
    return const {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(fileExtension);
  }

  bool get isPdf => fileExtension == 'pdf';

  bool get isOfficeDocument {
    return const {
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    }.contains(fileExtension);
  }

  bool get isExpiredByDate {
    if (expiresAt == null) return false;

    return expiresAt!.isBefore(DateTime.now());
  }

  /// A credential should be treated as expired when either:
  /// - the backend explicitly marks it EXPIRED, or
  /// - its actual expiration date has already passed.
  bool get isExpired {
    return status == CredentialStatus.expired || isExpiredByDate;
  }

  bool get isExpiringSoon {
    if (expiresAt == null || isExpired) {
      return false;
    }

    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 30));

    return expiresAt!.isAfter(now) && expiresAt!.isBefore(threshold);
  }

  int? get daysUntilExpiration {
    if (expiresAt == null) return null;

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final expiryDay = DateTime(
      expiresAt!.year,
      expiresAt!.month,
      expiresAt!.day,
    );

    return expiryDay.difference(today).inDays;
  }

  CredentialStatus get effectiveStatus {
    if (isExpired) {
      return CredentialStatus.expired;
    }

    return status;
  }

  bool get isApprovedAndCurrent {
    return status == CredentialStatus.approved && !isExpired;
  }

  bool get needsAttention {
    return status == CredentialStatus.rejected || isExpired || isExpiringSoon;
  }

  bool get isAwaitingReview {
    return status == CredentialStatus.pending;
  }

  bool get canDelete {
    return status != CredentialStatus.approved || isExpired;
  }

  bool get canReplace {
    return status == CredentialStatus.rejected || isExpired;
  }

  String get readinessMessage {
    if (isExpired) {
      return 'Expired';
    }

    if (status == CredentialStatus.rejected) {
      return 'Action required';
    }

    if (status == CredentialStatus.pending) {
      return 'Awaiting review';
    }

    if (isExpiringSoon) {
      final days = daysUntilExpiration;

      if (days == null) {
        return 'Expiring soon';
      }

      if (days == 0) {
        return 'Expires today';
      }

      if (days == 1) {
        return 'Expires tomorrow';
      }

      return 'Expires in $days days';
    }

    return 'Current';
  }
}
