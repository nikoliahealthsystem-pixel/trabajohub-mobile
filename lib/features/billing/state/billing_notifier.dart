import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/billing_repository.dart';
import 'billing_state.dart';

class BillingNotifier extends StateNotifier<BillingState> {
  final BillingRepository _repo;
  BillingNotifier(this._repo) : super(const BillingState());

  // ── Wallet ─────────────────────────────────────────────────

  Future<void> loadWallet() async {
    state = state.copyWith(walletStatus: BillingStatus.loading, walletError: null);
    try {
      final wallet = await _repo.getWallet();
      state = state.copyWith(walletStatus: BillingStatus.success, wallet: wallet);
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? e.message ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(
        walletStatus: BillingStatus.error,
        walletError: message,
      );
    }
  }

  // ── Payouts ────────────────────────────────────────────────

  Future<void> loadPayouts({bool refresh = false}) async {
    if (state.payoutsStatus == PayoutsStatus.loading) return;

    final page = refresh ? 1 : state.payoutsPage;
    final isFirst = refresh || state.payouts.isEmpty;

    state = state.copyWith(
      payoutsStatus:
      isFirst ? PayoutsStatus.loading : PayoutsStatus.loadingMore,
      payouts: refresh ? [] : state.payouts,
    );

    try {
      final result = await _repo.getPayouts(
        page: page,
        status: state.payoutsStatusFilter,
      );
      state = state.copyWith(
        payoutsStatus: PayoutsStatus.success,
        payouts: [...(refresh ? [] : state.payouts), ...result.payouts],
        payoutsTotal: result.total,
        payoutsHasMore: result.hasMore,
        payoutsPage: page + 1,
      );
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? e.message ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(
        payoutsStatus: PayoutsStatus.error,
        payoutsError: message,
      );
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(
      payoutsStatusFilter: status,
      payouts: [],
      payoutsPage: 1,
    );
    loadPayouts(refresh: true);
  }
}