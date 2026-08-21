import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/cache/cache_provider.dart';
import '../../../core/network/dio_client.dart';
import '../data/visits_api.dart';
import '../data/visits_repository.dart';
import '../data/visits_repository_impl.dart';
import '../state/visits_notifier.dart';
import '../state/visits_state.dart';

final visitsApiProvider = Provider<VisitsApi>((ref) {
  return VisitsApi(ref.watch(dioClientProvider));
});

final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  return VisitsRepositoryImpl(ref.watch(visitsApiProvider),ref.watch(appCacheProvider));
});

final visitsProvider =
StateNotifierProvider<VisitsNotifier, VisitsState>((ref) {
  return VisitsNotifier(ref.watch(visitsRepositoryProvider));
});

final visitDetailProvider =
FutureProvider.family<dynamic, String>((ref, id) async {
  return ref.watch(visitsRepositoryProvider).getVisit(id);
});