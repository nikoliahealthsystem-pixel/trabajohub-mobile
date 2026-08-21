import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_ttl.dart';
import 'billing_api.dart';
import 'billing_repository.dart';
import 'models/wallet_model.dart';
import 'models/payout_model.dart';

class BillingRepositoryImpl implements BillingRepository {
  final BillingApi _api;
  final AppCache _cache;

  BillingRepositoryImpl(this._api, this._cache);

  static const _walletKey = 'billing:wallet';
  static String _payoutsKey(int page, String? status) =>
      'billing:payouts:p$page:s=${status ?? ''}';

  @override
  Future<WalletModel> getWallet() async {
    final cached = _cache.get<WalletModel>(_walletKey);
    if (cached != null && !cached.isStale) return cached.data;

    final raw = await _api.fetchWallet();
    final wallet = WalletModel.fromJson(raw['data']);
    _cache.set(_walletKey, wallet, CacheTtl.me);
    return wallet;
  }

  @override
  Future<({List<PayoutModel> payouts, int total, bool hasMore})> getPayouts({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final key = _payoutsKey(page, status);
    final cached =
    _cache.get<({List<PayoutModel> payouts, int total, bool hasMore})>(key);
    if (cached != null && !cached.isStale) return cached.data;

    final raw = await _api.fetchPayouts(page: page, limit: limit, status: status);
    final data = raw['data'] as List? ?? [];
    final pagination = raw['pagination'] as Map<String, dynamic>? ?? {};

    final result = (
    payouts: data.map((j) => PayoutModel.fromJson(j)).toList(),
    total: pagination['total'] as int? ?? 0,
    hasMore: pagination['hasNext'] as bool? ?? false,
    );
    _cache.set(key, result, const Duration(minutes: 5));
    return result;
  }
}