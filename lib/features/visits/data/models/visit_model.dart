class VisitNurse {
  final String firstName;
  final String lastName;
  final String designation;
  const VisitNurse(
      {required this.firstName,
        required this.lastName,
        required this.designation});
  factory VisitNurse.fromJson(Map<String, dynamic> json) => VisitNurse(
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    designation: json['designation'] ?? '',
  );
  String get fullName => '$firstName $lastName';
}

class VisitShiftInfo {
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String visitType;
  final String? caseIdentifier;
  final String? city;
  final String? state;

  const VisitShiftInfo({
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.visitType,
    this.caseIdentifier,
    this.city,
    this.state,
  });

  factory VisitShiftInfo.fromJson(Map<String, dynamic> json) {
    final c = json['case'] as Map<String, dynamic>?;
    return VisitShiftInfo(
      scheduledStart: DateTime.parse(json['scheduledStart']),
      scheduledEnd: DateTime.parse(json['scheduledEnd']),
      visitType: json['visitType'] ?? '',
      caseIdentifier: c?['publicIdentifier'],
      city: c?['city'],
      state: c?['state'],
    );
  }

  String get locationDisplay =>
      (city != null && state != null) ? '$city, $state' : '—';
}

class VisitAuditEvent {
  final String id;
  final String action;
  final String? performedById;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const VisitAuditEvent({
    required this.id,
    required this.action,
    this.performedById,
    this.metadata,
    required this.createdAt,
  });

  factory VisitAuditEvent.fromJson(Map<String, dynamic> json) =>
      VisitAuditEvent(
        id: json['id'],
        action: json['action'],
        performedById: json['performedById'],
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

enum VisitStatus {
  scheduled, checkedIn, checkedOut, verified, flagged,
  overrideRequested, overrideApproved;

  static VisitStatus fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'CHECKED_IN': return checkedIn;
      case 'CHECKED_OUT': return checkedOut;
      case 'VERIFIED': return verified;
      case 'FLAGGED': return flagged;
      case 'OVERRIDE_REQUESTED': return overrideRequested;
      case 'OVERRIDE_APPROVED': return overrideApproved;
      default: return scheduled;
    }
  }

  String get label => name
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
      .trim()
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

class VisitModel {
  final String id;
  final String nurseProfileId;
  final String shiftId;
  final VisitStatus status;
  final DateTime? checkInTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkInDistance;
  final DateTime? checkOutTime;
  final double? checkOutDistance;
  final int? durationMinutes;
  final bool overrideRequired;
  final String? overrideReason;
  final String? notes;
  final DateTime createdAt;
  final VisitNurse? nurse;
  final VisitShiftInfo? shiftInfo;
  final List<VisitAuditEvent> auditEvents;

  const VisitModel({
    required this.id,
    required this.nurseProfileId,
    required this.shiftId,
    required this.status,
    this.checkInTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInDistance,
    this.checkOutTime,
    this.checkOutDistance,
    this.durationMinutes,
    required this.overrideRequired,
    this.overrideReason,
    this.notes,
    required this.createdAt,
    this.nurse,
    this.shiftInfo,
    this.auditEvents = const [],
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    final assignment = json['assignment'] as Map<String, dynamic>?;
    final shift = assignment?['shift'] as Map<String, dynamic>?;
    return VisitModel(
      id: json['id'],
      nurseProfileId: json['nurseProfileId'],
      shiftId: json['shiftId'],
      status: VisitStatus.fromString(json['status'] ?? ''),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      checkInLatitude: (json['checkInLatitude'] as num?)?.toDouble(),
      checkInLongitude: (json['checkInLongitude'] as num?)?.toDouble(),
      checkInDistance: (json['checkInDistance'] as num?)?.toDouble(),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      checkOutDistance:
      (json['checkOutDistance'] as num?)?.toDouble(),
      durationMinutes: json['durationMinutes'],
      overrideRequired: json['overrideRequired'] ?? false,
      overrideReason: json['overrideReason'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      nurse: json['nurseProfile'] != null
          ? VisitNurse.fromJson(json['nurseProfile'])
          : null,
      shiftInfo:
      shift != null ? VisitShiftInfo.fromJson(shift) : null,
      auditEvents: (json['auditEvents'] as List? ?? [])
          .map((e) => VisitAuditEvent.fromJson(e))
          .toList(),
    );
  }
}