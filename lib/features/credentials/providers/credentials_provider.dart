import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/cache/cache_provider.dart';
import '../../../core/network/dio_client.dart';
import '../data/credentials_api.dart';
import '../data/credentials_repository.dart';
import '../data/credentials_repository_impl.dart';
import '../state/credentials_notifier.dart';
import '../state/credentials_state.dart';

final credentialsApiProvider = Provider<CredentialsApi>((ref) {
  return CredentialsApi(ref.watch(dioClientProvider));
});

final credentialsRepositoryProvider =
Provider<CredentialsRepository>((ref) {
  return CredentialsRepositoryImpl(ref.watch(credentialsApiProvider), ref.watch(appCacheProvider));
});

final credentialsProvider =
StateNotifierProvider<CredentialsNotifier, CredentialsState>((ref) {
  return CredentialsNotifier(ref.watch(credentialsRepositoryProvider));
});