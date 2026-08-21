import '../../../../core/utils/json_utils.dart';
import 'payout_model.dart';

class WalletModel {
  final String id;
  final String nurseProfileId;
  final double pendingBalance;
  final double availableBalance;
  final double lifetimeEarnings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PayoutModel> recentPayouts;

  const WalletModel({
    required this.id,
    required this.nurseProfileId,
    required this.pendingBalance,
    required this.availableBalance,
    required this.lifetimeEarnings,
    required this.createdAt,
    required this.updatedAt,
    this.recentPayouts = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
    id: json['id'],
    nurseProfileId: json['nurseProfileId'],
    pendingBalance: parseDouble(json['pendingBalance']) ?? 0,
    availableBalance: parseDouble(json['availableBalance']) ?? 0,
    lifetimeEarnings: parseDouble(json['lifetimeEarnings']) ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    recentPayouts: (json['payouts'] as List? ?? [])
        .map((p) => PayoutModel.fromJson(p))
        .toList(),
  );
}