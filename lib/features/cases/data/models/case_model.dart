class CaseShiftSummary {
  final String id;
  final String visitType;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String status;
  final List<String> assignedNurses;

  const CaseShiftSummary({
    required this.id,
    required this.visitType,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    required this.assignedNurses,
  });

  factory CaseShiftSummary.fromJson(Map<String, dynamic> json) {
    final assignments = json['assignments'] as List? ?? [];
    return CaseShiftSummary(
      id: json['id'],
      visitType: json['visitType'] ?? '',
      scheduledStart: DateTime.parse(json['scheduledStart']),
      scheduledEnd: DateTime.parse(json['scheduledEnd']),
      status: json['status'] ?? '',
      assignedNurses: assignments
          .map<String>((a) {
        final np = a['nurseProfile'] as Map<String, dynamic>?;
        if (np == null) return '';
        return '${np['firstName']} ${np['lastName']}';
      })
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}

class CaseModel {
  final String id;
  final String facilityId;
  final String publicIdentifier;
  final String? patientFirstName;
  final String? patientLastName;
  final String? primaryDiagnosis;
  final String? notes;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String zipCode;
  final double? latitude;
  final double? longitude;
  final bool isOasisCase;
  final String visitType;
  final List<String> specialties;
  final bool isActive;
  final DateTime createdAt;
  final String? facilityName;
  final int shiftCount;
  final List<CaseShiftSummary> recentShifts;

  const CaseModel({
    required this.id,
    required this.facilityId,
    required this.publicIdentifier,
    this.patientFirstName,
    this.patientLastName,
    this.primaryDiagnosis,
    this.notes,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    this.latitude,
    this.longitude,
    required this.isOasisCase,
    required this.visitType,
    required this.specialties,
    required this.isActive,
    required this.createdAt,
    this.facilityName,
    this.shiftCount = 0,
    this.recentShifts = const [],
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
    id: json['id'],
    facilityId: json['facilityId'],
    publicIdentifier: json['publicIdentifier'],
    patientFirstName: json['patientFirstName'],
    patientLastName: json['patientLastName'],
    primaryDiagnosis: json['primaryDiagnosis'],
    notes: json['notes'],
    addressLine1: json['addressLine1'] ?? '',
    addressLine2: json['addressLine2'],
    city: json['city'] ?? '',
    state: json['state'] ?? '',
    zipCode: json['zipCode'] ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    isOasisCase: json['isOasisCase'] ?? false,
    visitType: json['visitType'] ?? '',
    specialties: List<String>.from(json['specialties'] ?? []),
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.parse(json['createdAt']),
    facilityName: json['facility']?['name'],
    shiftCount: json['_count']?['shifts'] as int? ?? 0,
    recentShifts: (json['shifts'] as List? ?? [])
        .map((s) => CaseShiftSummary.fromJson(s))
        .toList(),
  );

  String get locationDisplay => '$city, $state $zipCode';
  String get patientDisplay =>
      (patientFirstName != null && patientLastName != null)
          ? '$patientFirstName $patientLastName'
          : 'Patient (masked)';
}