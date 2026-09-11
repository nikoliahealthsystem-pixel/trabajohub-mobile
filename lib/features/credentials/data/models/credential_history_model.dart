enum CredentialHistoryAction {
  upload,
  approve,
  reject,
  delete,
  update,
  download,
  unknown;

  static CredentialHistoryAction fromString(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'UPLOAD':
        return CredentialHistoryAction.upload;
      case 'APPROVE':
        return CredentialHistoryAction.approve;
      case 'REJECT':
        return CredentialHistoryAction.reject;
      case 'DELETE':
        return CredentialHistoryAction.delete;
      case 'UPDATE':
        return CredentialHistoryAction.update;
      case 'DOWNLOAD':
        return CredentialHistoryAction.download;
      default:
        return CredentialHistoryAction.unknown;
    }
  }

  String get label {
    switch (this) {
      case CredentialHistoryAction.upload:
        return 'Document uploaded';
      case CredentialHistoryAction.approve:
        return 'Credential approved';
      case CredentialHistoryAction.reject:
        return 'Credential rejected';
      case CredentialHistoryAction.delete:
        return 'Credential deleted';
      case CredentialHistoryAction.update:
        return 'Credential updated';
      case CredentialHistoryAction.download:
        return 'Document accessed';
      case CredentialHistoryAction.unknown:
        return 'Credential activity';
    }
  }
}

enum CredentialHistoryActor {
  nurse,
  trabajohub,
  system;

  static CredentialHistoryActor fromString(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'NURSE':
        return CredentialHistoryActor.nurse;
      case 'TRABAJOHUB':
        return CredentialHistoryActor.trabajohub;
      default:
        return CredentialHistoryActor.system;
    }
  }

  String get label {
    switch (this) {
      case CredentialHistoryActor.nurse:
        return 'You';
      case CredentialHistoryActor.trabajohub:
        return 'TrabajoHub';
      case CredentialHistoryActor.system:
        return 'System';
    }
  }
}

class CredentialHistoryEvent {
  final String id;
  final CredentialHistoryAction action;
  final String? status;
  final String? reason;
  final DateTime createdAt;
  final CredentialHistoryActor performedBy;

  const CredentialHistoryEvent({
    required this.id,
    required this.action,
    this.status,
    this.reason,
    required this.createdAt,
    required this.performedBy,
  });

  factory CredentialHistoryEvent.fromJson(Map<String, dynamic> json) {
    return CredentialHistoryEvent(
      id: json['id']?.toString() ?? '',
      action: CredentialHistoryAction.fromString(json['action']?.toString()),
      status: _nullableString(json['status']),
      reason: _nullableString(json['reason']),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      performedBy: CredentialHistoryActor.fromString(
        json['performedBy']?.toString(),
      ),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  bool get isPositive => action == CredentialHistoryAction.approve;

  bool get requiresAttention => action == CredentialHistoryAction.reject;

  String get description {
    switch (action) {
      case CredentialHistoryAction.upload:
        return 'Submitted for credential review.';

      case CredentialHistoryAction.approve:
        return 'Approved and available for applicable shift eligibility.';

      case CredentialHistoryAction.reject:
        if (reason != null && reason!.isNotEmpty) {
          return reason!;
        }

        return 'The credential did not pass review.';

      case CredentialHistoryAction.delete:
        return 'This credential record was removed.';

      case CredentialHistoryAction.update:
        return 'Credential information was updated.';

      case CredentialHistoryAction.download:
        return 'The credential document was accessed.';

      case CredentialHistoryAction.unknown:
        return 'Credential activity was recorded.';
    }
  }
}

class CredentialHistoryResult {
  final String credentialId;
  final String type;
  final String? customLabel;
  final List<CredentialHistoryEvent> events;

  const CredentialHistoryResult({
    required this.credentialId,
    required this.type,
    this.customLabel,
    required this.events,
  });

  factory CredentialHistoryResult.fromJson(Map<String, dynamic> json) {
    final credential = json['credential'] as Map<String, dynamic>? ?? {};

    final history = json['history'] as List? ?? [];

    return CredentialHistoryResult(
      credentialId: credential['id']?.toString() ?? '',
      type: credential['type']?.toString() ?? '',
      customLabel: credential['customLabel']?.toString(),
      events: history
          .whereType<Map>()
          .map(
            (event) => CredentialHistoryEvent.fromJson(
              Map<String, dynamic>.from(event),
            ),
          )
          .toList(),
    );
  }
}
