class ShiftCase {
  final String publicIdentifier;
  final String city;
  final String state;
  final double? latitude;
  final double? longitude;
  final List<String> specialties;
  final String visitType;

  const ShiftCase({
    required this.publicIdentifier,
    required this.city,
    required this.state,
    this.latitude,
    this.longitude,
    required this.specialties,
    required this.visitType,
  });

  factory ShiftCase.fromJson(Map<String, dynamic> json) => ShiftCase(
    publicIdentifier: json['publicIdentifier'] ?? '',
    city: json['city'] ?? '',
    state: json['state'] ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    specialties: List<String>.from(json['specialties'] ?? []),
    visitType: json['visitType'] ?? '',
  );
}

class ShiftModel {
  final String id;
  final String caseId;
  final String facilityId;
  final String? title;
  final String? description;
  final String visitType;
  final String requiredDesignation;
  final List<String> specialties;
  final String pattern;
  final String period;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final int? estimatedDuration;
  final String status;
  final bool isUrgent;
  final bool isEmergencyFill;
  final bool allowInstantBook;
  final double chargeRate;
  final double payRate;
  final String billingType;
  final ShiftCase? shiftCase;

  const ShiftModel({
    required this.id,
    required this.caseId,
    required this.facilityId,
    this.title,
    this.description,
    required this.visitType,
    required this.requiredDesignation,
    required this.specialties,
    required this.pattern,
    required this.period,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.estimatedDuration,
    required this.status,
    required this.isUrgent,
    required this.isEmergencyFill,
    required this.allowInstantBook,
    required this.chargeRate,
    required this.payRate,
    required this.billingType,
    this.shiftCase,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) => ShiftModel(
    id: json['id'],
    caseId: json['caseId'],
    facilityId: json['facilityId'],
    title: json['title'],
    description: json['description'],
    visitType: json['visitType'],
    requiredDesignation: json['requiredDesignation'],
    specialties: List<String>.from(json['specialties'] ?? []),
    pattern: json['pattern'] ?? 'ONE_TIME',
    period: json['period'] ?? 'DAY',
    scheduledStart: DateTime.parse(json['scheduledStart']),
    scheduledEnd: DateTime.parse(json['scheduledEnd']),
    estimatedDuration: json['estimatedDuration'],
    status: json['status'],
    isUrgent: json['isUrgent'] ?? false,
    isEmergencyFill: json['isEmergencyFill'] ?? false,
    allowInstantBook: json['allowInstantBook'] ?? true,
    chargeRate: double.tryParse(json['chargeRate'].toString()) ?? 0,
    payRate: double.tryParse(json['payRate'].toString()) ?? 0,
    billingType: json['billingType'] ?? 'HOURLY',
    shiftCase: json['case'] != null ? ShiftCase.fromJson(json['case']) : null,
  );

  String get displayTitle =>
      title ?? '${_formatVisitType(visitType)} – ${requiredDesignation}';

  String get locationDisplay =>
      shiftCase != null ? '${shiftCase!.city}, ${shiftCase!.state}' : 'Unknown location';

  double get estimatedEarnings {
    final hours = scheduledEnd.difference(scheduledStart).inMinutes / 60;
    return payRate * hours;
  }

  static String _formatVisitType(String raw) =>
      raw.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
}