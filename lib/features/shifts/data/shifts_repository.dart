import 'models/shift_model.dart';
import 'models/shift_assignment_model.dart';
import 'models/cancellation_preview.dart';

abstract class ShiftsRepository {
  Future<({List<ShiftModel> shifts, int total, int page})> getMarketplace({
    int page,
    int limit,
    String? visitType,
    bool? isUrgent,
    double? minPay,
    double? maxPay,
    String? date,
    String? searchQuery,
  });

  Future<({List<ShiftAssignmentModel> assignments, int total, int page})>
  getMyShifts({int page, int limit, String? category});

  Future<ShiftModel> getShiftById(String id);

  Future<ShiftAssignmentModel> bookShift(String shiftId);

  Future<CancellationPreview> getCancellationPreview(String shiftId);

  Future<Map<String, dynamic>> cancelShift(
    String shiftId, {
    required String reason,
    required double expectedPenaltyAmount,
    required String expectedPolicyVersion,
  });
}
