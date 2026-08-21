import 'models/wallet_model.dart';
import 'models/payout_model.dart';

abstract class BillingRepository {
  Future<WalletModel> getWallet();
  Future<({List<PayoutModel> payouts, int total, bool hasMore})> getPayouts({
    int page,
    int limit,
    String? status,
  });
}