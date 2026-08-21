import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/cache/cache_provider.dart';
import '../../../core/network/dio_client.dart';
import '../data/shifts_api.dart';
import '../data/shifts_repository.dart';
import '../data/shifts_repository_impl.dart';
import '../state/marketplace_notifier.dart';
import '../state/marketplace_state.dart';
import '../state/my_shifts_notifier.dart';
import '../state/my_shifts_state.dart';

final shiftsApiProvider = Provider<ShiftsApi>((ref) {
  final client = ref.watch(dioClientProvider);
  return ShiftsApi(client);
});

final shiftsRepositoryProvider = Provider<ShiftsRepository>((ref) {
  return ShiftsRepositoryImpl(ref.watch(shiftsApiProvider),
    ref.watch(appCacheProvider), );
});

final marketplaceProvider =
StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier(ref.watch(shiftsRepositoryProvider));
});

final myShiftsProvider =
StateNotifierProvider<MyShiftsNotifier, MyShiftsState>((ref) {
  return MyShiftsNotifier(ref.watch(shiftsRepositoryProvider));
});

// Single-shift detail — auto-disposed
final shiftDetailProvider =
FutureProvider.family<dynamic, String>((ref, id) async {
  final repo = ref.watch(shiftsRepositoryProvider);
  return repo.getShiftById(id);
});