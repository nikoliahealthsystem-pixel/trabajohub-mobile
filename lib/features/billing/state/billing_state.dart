import '../data/models/wallet_model.dart';
import '../data/models/payout_model.dart';

const _sentinel = Object();

enum BillingStatus { initial, loading, success, error }

enum PayoutsStatus { initial, loading, loadingMore, success, error }

class BillingState {
  // ── Wallet ────────────────────────────────────────────────
  final BillingStatus walletStatus;
  final WalletModel? wallet;
  final String? walletError;

  // ── Payouts ───────────────────────────────────────────────
  final PayoutsStatus payoutsStatus;
  final List<PayoutModel> payouts;
  final int payoutsTotal;
  final bool payoutsHasMore;
  final int payoutsPage;
  final String? payoutsStatusFilter;
  final String? payoutsError;

  const BillingState({
    this.walletStatus = BillingStatus.initial,
    this.wallet,
    this.walletError,
    this.payoutsStatus = PayoutsStatus.initial,
    this.payouts = const [],
    this.payoutsTotal = 0,
    this.payoutsHasMore = false,
    this.payoutsPage = 1,
    this.payoutsStatusFilter,
    this.payoutsError,
  });

  BillingState copyWith({
    BillingStatus? walletStatus,
    Object? wallet = _sentinel,
    Object? walletError = _sentinel,
    PayoutsStatus? payoutsStatus,
    List<PayoutModel>? payouts,
    int? payoutsTotal,
    bool? payoutsHasMore,
    int? payoutsPage,
    Object? payoutsStatusFilter = _sentinel,
    Object? payoutsError = _sentinel,
  }) =>
      BillingState(
        walletStatus: walletStatus ?? this.walletStatus,
        wallet: wallet == _sentinel ? this.wallet : wallet as WalletModel?,
        walletError: walletError == _sentinel
            ? this.walletError
            : walletError as String?,
        payoutsStatus: payoutsStatus ?? this.payoutsStatus,
        payouts: payouts ?? this.payouts,
        payoutsTotal: payoutsTotal ?? this.payoutsTotal,
        payoutsHasMore: payoutsHasMore ?? this.payoutsHasMore,
        payoutsPage: payoutsPage ?? this.payoutsPage,
        payoutsStatusFilter: payoutsStatusFilter == _sentinel
            ? this.payoutsStatusFilter
            : payoutsStatusFilter as String?,
        payoutsError: payoutsError == _sentinel
            ? this.payoutsError
            : payoutsError as String?,
      );
}