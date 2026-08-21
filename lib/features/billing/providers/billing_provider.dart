import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/cache/cache_provider.dart';
import '../../../core/network/dio_client.dart';
import '../data/billing_api.dart';
import '../data/billing_repository.dart';
import '../data/billing_repository_impl.dart';
import '../state/billing_notifier.dart';
import '../state/billing_state.dart';

final billingApiProvider = Provider<BillingApi>((ref) {
  return BillingApi(ref.watch(dioClientProvider));
});

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepositoryImpl(
    ref.watch(billingApiProvider),
    ref.watch(appCacheProvider),
  );
});

final billingProvider =
StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  return BillingNotifier(ref.watch(billingRepositoryProvider));
});