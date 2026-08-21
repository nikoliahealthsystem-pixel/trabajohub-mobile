import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/cache/cache_provider.dart';
import '../../../core/network/dio_client.dart';
import '../data/cases_api.dart';
import '../data/cases_repository.dart';
import '../data/cases_repository_impl.dart';
import '../state/cases_notifier.dart';
import '../state/cases_state.dart';

final casesApiProvider = Provider<CasesApi>((ref) {
  return CasesApi(ref.watch(dioClientProvider));
});

final casesRepositoryProvider = Provider<CasesRepository>((ref) {
  return CasesRepositoryImpl(ref.watch(casesApiProvider), ref.watch(appCacheProvider));
});

final casesProvider =
StateNotifierProvider<CasesNotifier, CasesState>((ref) {
  return CasesNotifier(ref.watch(casesRepositoryProvider));
});

final caseDetailProvider =
FutureProvider.family<dynamic, String>((ref, id) async {
  return ref.watch(casesRepositoryProvider).getCase(id);
});