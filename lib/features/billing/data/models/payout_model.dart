import '../../../../core/utils/json_utils.dart';

enum PayoutStatus {
  pending,
  settled,
  failed;

  static PayoutStatus fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'SETTLED': return settled;
      case 'FAILED': return failed;
      default: return pending;
    }
  }

  String get label => name[0].toUpperCase() + name.substring(1);
}

class PayoutModel {
  final String id;
  final String nurseProfileId;
  final String walletId;
  final String? shiftId;
  final double grossCharge;
  final double netPayout;
  final double systemCommission;
  final String? stripeTransferId;
  final PayoutStatus status;
  final String? notes;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PayoutModel({
    required this.id,
    required this.nurseProfileId,
    required this.walletId,
    this.shiftId,
    required this.grossCharge,
    required this.netPayout,
    required this.systemCommission,
    this.stripeTransferId,
    required this.status,
    this.notes,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) => PayoutModel(
    id: json['id'],
    nurseProfileId: json['nurseProfileId'],
    walletId: json['walletId'],
    shiftId: json['shiftId'],
    grossCharge: parseDouble(json['grossCharge']) ?? 0,
    netPayout: parseDouble(json['netPayout']) ?? 0,
    systemCommission: parseDouble(json['systemCommission']) ?? 0,
    stripeTransferId: json['stripeTransferId'],
    status: PayoutStatus.fromString(json['status'] ?? ''),
    notes: json['notes'],
    paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}