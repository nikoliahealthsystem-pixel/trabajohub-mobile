import '../data/models/shift_assignment_model.dart';

enum MyShiftsStatus { initial, loading, loadingMore, success, error }

class MyShiftsState {
  final MyShiftsStatus status;
  final List<ShiftAssignmentModel> assignments;
  final int currentPage;
  final int total;
  final String? errorMessage;
  final String selectedTab; // 'ACCEPTED' | 'COMPLETED' | 'CANCELLED'
  final String? cancellingId;

  const MyShiftsState({
    this.status = MyShiftsStatus.initial,
    this.assignments = const [],
    this.currentPage = 1,
    this.total = 0,
    this.errorMessage,
    this.selectedTab = 'ACCEPTED',
    this.cancellingId,
  });

  bool get hasMore => assignments.length < total;

  MyShiftsState copyWith({
    MyShiftsStatus? status,
    List<ShiftAssignmentModel>? assignments,
    int? currentPage,
    int? total,
    String? errorMessage,
    String? selectedTab,
    Object? cancellingId = _sentinel,
  }) =>
      MyShiftsState(
        status: status ?? this.status,
        assignments: assignments ?? this.assignments,
        currentPage: currentPage ?? this.currentPage,
        total: total ?? this.total,
        errorMessage: errorMessage ?? this.errorMessage,
        selectedTab: selectedTab ?? this.selectedTab,
        cancellingId: cancellingId == _sentinel ? this.cancellingId : cancellingId as String?,
      );
}

const _sentinel = Object();