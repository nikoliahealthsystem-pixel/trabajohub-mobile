import 'models/shift_model.dart';
import 'models/shift_assignment_model.dart';

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

  Future<({List<ShiftAssignmentModel> assignments, int total, int page})> getMyShifts({
    int page,
    int limit,
    String? status,
  });

  Future<ShiftModel> getShiftById(String id);
  Future<ShiftAssignmentModel> bookShift(String shiftId);
  Future<void> cancelShift(String shiftId, {String? reason});
}