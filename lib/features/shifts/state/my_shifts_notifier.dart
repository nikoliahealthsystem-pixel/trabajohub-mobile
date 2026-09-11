import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/models/cancellation_preview.dart';
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
        category: state.selectedTab,
      );

      state = state.copyWith(
        status: MyShiftsStatus.success,
        assignments: [
          ...(refresh ? [] : state.assignments),
          ...result.assignments,
        ],
        currentPage: page + 1,
        total: result.total,
      );
    } catch (e) {
      final msg = e is DioException
          ? (e.message ?? 'Something went wrong')
          : e.toString();

      state = state.copyWith(status: MyShiftsStatus.error, errorMessage: msg);
    }
  }

  Future<void> switchTab(String tab) async {
    if (state.selectedTab == tab) return;

    state = state.copyWith(selectedTab: tab, assignments: [], currentPage: 1);

    await load(refresh: true);
  }

  Future<CancellationPreview> getCancellationPreview(String shiftId) {
    return _repo.getCancellationPreview(shiftId);
  }

  Future<bool> cancelShift(
    String shiftId, {
    required String reason,
    required double expectedPenaltyAmount,
    required String expectedPolicyVersion,
  }) async {
    state = state.copyWith(cancellingId: shiftId, errorMessage: null);

    try {
      await _repo.cancelShift(
        shiftId,
        reason: reason,
        expectedPenaltyAmount: expectedPenaltyAmount,
        expectedPolicyVersion: expectedPolicyVersion,
      );

      state = state.copyWith(
        cancellingId: null,
        assignments: state.assignments
            .where((a) => a.shiftId != shiftId)
            .toList(),
        total: state.total > 0 ? state.total - 1 : 0,
      );

      return true;
    } catch (e) {
      String msg = 'Failed to cancel shift';

      if (e is DioException) {
        final data = e.response?.data;

        if (data is Map) {
          final code = data['code']?.toString();

          if (code == 'CANCELLATION_POLICY_CHANGED') {
            final penaltyRaw = data['penaltyAmount'];
            final windowRaw = data['cancellationWindowHours'];

            final penalty = penaltyRaw is num
                ? penaltyRaw.toDouble()
                : double.tryParse(penaltyRaw?.toString() ?? '');

            final window = windowRaw is num
                ? windowRaw.toInt()
                : int.tryParse(windowRaw?.toString() ?? '');

            final penaltyText = penalty == null
                ? 'the cancellation fee has changed'
                : penalty <= 0
                ? 'no cancellation fee currently applies'
                : 'the cancellation fee is now '
                      '\$${penalty.toStringAsFixed(2)}';

            final windowText = window == null
                ? ''
                : ' The current late-cancellation window is $window hours.';

            msg =
                'The cancellation policy changed before your request was submitted. '
                '$penaltyText.$windowText Please review the updated policy and confirm again.';
          } else if (data['message'] is String) {
            final backendMessage = (data['message'] as String).trim();

            if (backendMessage.isNotEmpty) {
              msg = backendMessage;
            }
          }
        } else if (e.message != null && e.message!.trim().isNotEmpty) {
          msg = e.message!.trim();
        }
      } else {
        final text = e.toString().trim();

        if (text.isNotEmpty) {
          msg = text;
        }
      }

      state = state.copyWith(cancellingId: null, errorMessage: msg);

      return false;
    }
  }
}
