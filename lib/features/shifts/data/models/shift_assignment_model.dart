import '../../../visits/data/models/visit_model.dart';
import 'shift_model.dart';

class ShiftAssignmentModel {
  final String id;
  final String shiftId;
  final String nurseProfileId;
  final String status;
  final DateTime? acceptedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final ShiftModel? shift;
  final VisitModel? visit;

  const ShiftAssignmentModel({
    required this.id,
    required this.shiftId,
    required this.nurseProfileId,
    required this.status,
    this.acceptedAt,
    this.cancelledAt,
    this.cancelReason,
    this.shift,
    this.visit,
  });

  factory ShiftAssignmentModel.fromJson(Map<String, dynamic> json) =>
      ShiftAssignmentModel(
        id: json['id'],
        shiftId: json['shiftId'],
        nurseProfileId: json['nurseProfileId'],
        status: json['status'],
        acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
        cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
        cancelReason: json['cancelReason'],
        shift: json['shift'] != null ? ShiftModel.fromJson(json['shift']) : null,
        visit: json['visit'] != null ? VisitModel.fromJson(json['visit']) : null,
      );
}