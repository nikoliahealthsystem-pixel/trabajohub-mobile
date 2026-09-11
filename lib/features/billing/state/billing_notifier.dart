import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/billing_repository.dart';
import '../data/models/payout_model.dart';
import 'billing_state.dart';

class BillingNotifier extends StateNotifier<BillingState> {
  final BillingRepository _repo;

  BillingNotifier(this._repo) : super(const BillingState());

  // ── Wallet ─────────────────────────────────────────────────

  Future<void> loadWallet() async {
    state = state.copyWith(
      walletStatus: BillingStatus.loading,
      wallet: null,
      walletError: null,
    );

    try {
      final wallet = await _repo.getWallet();

      state = state.copyWith(
        walletStatus: BillingStatus.success,
        wallet: wallet,
        walletError: null,
      );
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? e.message ?? 'Something went wrong')
          : e.toString();

      state = state.copyWith(
        walletStatus: BillingStatus.error,
        wallet: null,
        walletError: message,
      );
    }
  }

  // ── Payouts ────────────────────────────────────────────────

  Future<void> loadPayouts({bool refresh = false}) async {
    if (state.payoutsStatus == PayoutsStatus.loading) {
      return;
    }

    final page = refresh ? 1 : state.payoutsPage;
    final isFirst = refresh || state.payouts.isEmpty;

    state = state.copyWith(
      payoutsStatus: isFirst
          ? PayoutsStatus.loading
          : PayoutsStatus.loadingMore,
      payouts: refresh ? [] : state.payouts,
      payoutsTotal: refresh ? 0 : state.payoutsTotal,
      payoutsHasMore: refresh ? false : state.payoutsHasMore,
      payoutsPage: refresh ? 1 : state.payoutsPage,
      payoutsError: null,
    );

    try {
      final result = await _repo.getPayouts(
        page: page,
        status: state.payoutsStatusFilter,
      );

      final List<PayoutModel> currentPayouts = refresh
          ? <PayoutModel>[]
          : state.payouts;
      state = state.copyWith(
        payoutsStatus: PayoutsStatus.success,
        payouts: [...currentPayouts, ...result.payouts],
        payoutsTotal: result.total,
        payoutsHasMore: result.hasMore,
        payoutsPage: page + 1,
        payoutsError: null,
      );
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? e.message ?? 'Something went wrong')
          : e.toString();

      state = state.copyWith(
        payoutsStatus: PayoutsStatus.error,
        payouts: refresh ? [] : state.payouts,
        payoutsTotal: refresh ? 0 : state.payoutsTotal,
        payoutsHasMore: refresh ? false : state.payoutsHasMore,
        payoutsPage: refresh ? 1 : state.payoutsPage,
        payoutsError: message,
      );
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(
      payoutsStatusFilter: status,
      payouts: [],
      payoutsTotal: 0,
      payoutsHasMore: false,
      payoutsPage: 1,
      payoutsError: null,
    );

    loadPayouts(refresh: true);
  }
}
