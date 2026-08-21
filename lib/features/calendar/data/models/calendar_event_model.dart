class CalendarEventMeta {
  final String? caseIdentifier;
  final String? location;
  final String? visitType;
  final String? designation;
  final List<String> specialties;
  final String? assignee;
  final String? nurse;
  final String? shiftId;
  final String? pattern;
  final String? period;
  final bool isUrgent;
  final bool isEmergencyFill;
  final double? payRate;
  final double? chargeRate;
  final int? durationMinutes;
  final String? checkInTime;
  final String? checkOutTime;
  final double? checkInDistance;
  final bool overrideRequired;
  final String? overrideReason;
  final String? notes;
  final String? credentialType;
  final String? customLabel;
  final String? expiresAt;
  final int? daysUntilExpiry;
  final String? nurseProfileId;
  final String? invoiceNumber;
  final double? total;
  final String? dueAt;
  final String? facilityName;

  const CalendarEventMeta({
    this.caseIdentifier,
    this.location,
    this.visitType,
    this.designation,
    this.specialties = const [],
    this.assignee,
    this.nurse,
    this.shiftId,
    this.pattern,
    this.period,
    this.isUrgent = false,
    this.isEmergencyFill = false,
    this.payRate,
    this.chargeRate,
    this.durationMinutes,
    this.checkInTime,
    this.checkOutTime,
    this.checkInDistance,
    this.overrideRequired = false,
    this.overrideReason,
    this.notes,
    this.credentialType,
    this.customLabel,
    this.expiresAt,
    this.daysUntilExpiry,
    this.nurseProfileId,
    this.invoiceNumber,
    this.total,
    this.dueAt,
    this.facilityName,
  });

  factory CalendarEventMeta.fromJson(Map<String, dynamic> json) =>
      CalendarEventMeta(
        caseIdentifier: json['caseIdentifier'],
        location: json['location'],
        visitType: json['visitType'],
        designation: json['designation'],
        specialties: List<String>.from(json['specialties'] ?? []),
        assignee: json['assignee'],
        nurse: json['nurse'],
        shiftId: json['shiftId'],
        pattern: json['pattern'],
        period: json['period'],
        isUrgent: json['isUrgent'] ?? false,
        isEmergencyFill: json['isEmergencyFill'] ?? false,
        payRate:     _parseDouble(json['payRate']),
        chargeRate:  _parseDouble(json['chargeRate']),
        durationMinutes: json['durationMinutes'],
        checkInTime: json['checkInTime'],
        checkOutTime: json['checkOutTime'],
        checkInDistance: _parseDouble(json['checkInDistance']),
        overrideRequired: json['overrideRequired'] ?? false,
        overrideReason: json['overrideReason'],
        notes: json['notes'],
        credentialType: json['credentialType'],
        customLabel: json['customLabel'],
        expiresAt: json['expiresAt'],
        daysUntilExpiry: json['daysUntilExpiry'],
        nurseProfileId: json['nurseProfileId'],
        invoiceNumber: json['invoiceNumber'],
        total:       _parseDouble(json['total']),
        dueAt: json['dueAt'],
        facilityName: json['facilityName'],
      );
}

enum CalendarEventType {
  shift,
  recurringShift,
  visit,
  credentialExpiry,
  invoiceDue,
  invoiceOverdue;

  static CalendarEventType fromString(String raw) {
    switch (raw) {
      case 'SHIFT': return shift;
      case 'RECURRING_SHIFT': return recurringShift;
      case 'VISIT': return visit;
      case 'CREDENTIAL_EXPIRY': return credentialExpiry;
      case 'INVOICE_DUE': return invoiceDue;
      case 'INVOICE_OVERDUE': return invoiceOverdue;
      default: return shift;
    }
  }

  String toApiString() {
    switch (this) {
      case shift: return 'SHIFT';
      case recurringShift: return 'RECURRING_SHIFT';
      case visit: return 'VISIT';
      case credentialExpiry: return 'CREDENTIAL_EXPIRY';
      case invoiceDue: return 'INVOICE_DUE';
      case invoiceOverdue: return 'INVOICE_OVERDUE';
    }
  }

  String get label {
    switch (this) {
      case shift: return 'Shift';
      case recurringShift: return 'Recurring';
      case visit: return 'Visit';
      case credentialExpiry: return 'Credential';
      case invoiceDue: return 'Invoice Due';
      case invoiceOverdue: return 'Overdue';
    }
  }

  String get emoji {
    switch (this) {
      case shift: return '🩺';
      case recurringShift: return '🔁';
      case visit: return '📍';
      case credentialExpiry: return '📋';
      case invoiceDue: return '💳';
      case invoiceOverdue: return '⚠️';
    }
  }
}

class CalendarEventModel {
  final String id;
  final CalendarEventType type;
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String colorHex;
  final String status;
  final String resourceId;
  final String? facilityId;
  final CalendarEventMeta meta;

  const CalendarEventModel({
    required this.id,
    required this.type,
    required this.title,
    required this.start,
    this.end,
    required this.allDay,
    required this.colorHex,
    required this.status,
    required this.resourceId,
    this.facilityId,
    required this.meta,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) =>
      CalendarEventModel(
        id: json['id'],
        type: CalendarEventType.fromString(json['type']),
        title: json['title'],
        start: DateTime.parse(json['start']),
        end: json['end'] != null ? DateTime.parse(json['end']) : null,
        allDay: json['allDay'] ?? false,
        colorHex: json['color'] ?? '#3B82F6',
        status: json['status'] ?? '',
        resourceId: json['resourceId'] ?? '',
        facilityId: json['facilityId'],
        meta: CalendarEventMeta.fromJson(
            json['meta'] as Map<String, dynamic>? ?? {}),
      );

  // Normalize to the calendar day key (UTC midnight)
  DateTime get dayKey => DateTime.utc(start.year, start.month, start.day);
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}