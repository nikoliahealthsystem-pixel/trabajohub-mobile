import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/shifts_repository.dart';
import 'my_shifts_state.dart';

class MyShiftsNotifier extends StateNotifier<MyShiftsState> {
  final ShiftsRepository _repo;
  MyShiftsNotifier(this._repo) : super(const MyShiftsState());

  Future<void> load({bool refresh = false}) async {
    if (state.status == MyShiftsStatus.loading) return;

    final page = refresh ? 1 : state.currentPage;
    final isFirstLoad = state.assignments.isEmpty || refresh;

    state = state.copyWith(
      status: isFirstLoad ? MyShiftsStatus.loading : MyShiftsStatus.loadingMore,
      assignments: refresh ? [] : state.assignments,
    );

    try {
      final result = await _repo.getMyShifts(
        page: page,
        status: state.selectedTab,
      );
      state = state.copyWith(
        status: MyShiftsStatus.success,
        assignments: [...(refresh ? [] : state.assignments), ...result.assignments],
        currentPage: page + 1,
        total: result.total,
      );
    } catch (e) {
      final msg = e is DioException ? (e.message ?? 'Something went wrong') : e.toString();
      state = state.copyWith(
        status: MyShiftsStatus.error,
        errorMessage: msg,
      );
    }
  }

  Future<void> switchTab(String tab) async {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab, assignments: [], currentPage: 1);
    await load(refresh: true);
  }

  Future<bool> cancelShift(String shiftId, {String? reason}) async {
    state = state.copyWith(cancellingId: shiftId);
    try {
      await _repo.cancelShift(shiftId, reason: reason);
      state = state.copyWith(
        cancellingId: null,
        assignments: state.assignments.where((a) => a.shiftId != shiftId).toList(),
        total: state.total - 1,
      );
      return true;
    } catch (e) {
      final msg = e is DioException ? (e.message ?? 'Something went wrong') : e.toString();
      state = state.copyWith(cancellingId: null,errorMessage: msg);
      return false;
    }
  }
}