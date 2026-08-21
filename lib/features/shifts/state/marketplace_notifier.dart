import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/shifts_repository.dart';
import 'marketplace_state.dart';

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final ShiftsRepository _repo;
  MarketplaceNotifier(this._repo) : super(const MarketplaceState());

  Future<void> load({bool refresh = false}) async {
    if (state.status == MarketplaceStatus.loading) return;

    final isFirstLoad = state.shifts.isEmpty || refresh;
    final currentFilter = state.filter;

    state = state.copyWith(
      status: isFirstLoad ? MarketplaceStatus.loading : MarketplaceStatus.loadingMore,
      shifts: refresh ? [] : state.shifts,
      // Keep filter as is
    );

    try {
      final result = await _repo.getMarketplace(
        page: refresh ? 1 : state.currentPage,
        visitType: currentFilter.visitType,
        isUrgent: currentFilter.isUrgent,
        minPay: currentFilter.minPay,
        maxPay: currentFilter.maxPay,
        date: currentFilter.date,
        searchQuery: currentFilter.searchQuery,   // ← This was likely missing or stale
      );

      state = state.copyWith(
        status: MarketplaceStatus.success,
        shifts: [...(refresh ? [] : state.shifts), ...result.shifts],
        currentPage: (refresh ? 1 : state.currentPage) + 1,
        total: result.total,
        //hasMore: result.shifts.length >= 20, // or use pagination info
      );
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();

      state = state.copyWith(
        status: MarketplaceStatus.error,
        errorMessage: message,
      );
    }
  }

  Future<void> applyFilter(MarketplaceFilter filter) async {
    state = state.copyWith(
      filter: filter,
      currentPage: 1,        // Important: Reset pagination
      shifts: [],            // Clear current list
    );

    await load(refresh: true);
  }

  Future<bool> bookShift(String shiftId) async {
    state = state.copyWith(bookingShiftId: shiftId, bookingError: null);
    try {
      await _repo.bookShift(shiftId);
      // Remove booked shift from marketplace list
      state = state.copyWith(
        bookingShiftId: null,
        shifts: state.shifts.where((s) => s.id != shiftId).toList(),
        total: state.total - 1,
      );
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(bookingShiftId: null, bookingError: message);
      return false;
    }
  }
}