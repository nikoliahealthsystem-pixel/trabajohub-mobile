class CancellationPreview {
  final String assignmentId;
  final String shiftId;
  final double hoursUntilStart;
  final int cancellationWindowHours;
  final double lateCancellationFineAmount;
  final bool isLateCancellation;
  final double penaltyAmount;
  final String policyVersion;

  const CancellationPreview({
    required this.assignmentId,
    required this.shiftId,
    required this.hoursUntilStart,
    required this.cancellationWindowHours,
    required this.lateCancellationFineAmount,
    required this.isLateCancellation,
    required this.penaltyAmount,
    required this.policyVersion,
  });

  factory CancellationPreview.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CancellationPreview(
      assignmentId: json['assignmentId']?.toString() ?? '',
      shiftId: json['shiftId']?.toString() ?? '',
      hoursUntilStart: asDouble(json['hoursUntilStart']),
      cancellationWindowHours: asInt(json['cancellationWindowHours']),
      lateCancellationFineAmount: asDouble(json['lateCancellationFineAmount']),
      isLateCancellation: json['isLateCancellation'] == true,
      penaltyAmount: asDouble(json['penaltyAmount']),
      policyVersion: json['policyVersion']?.toString() ?? '',
    );
  }
}
