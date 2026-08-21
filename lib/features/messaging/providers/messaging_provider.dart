import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/cache/cache_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/socket/socket_provider.dart';
import '../data/messaging_api.dart';
import '../data/messaging_repository.dart';
import '../data/messaging_repository_impl.dart';
import '../state/messaging_notifier.dart';
import '../state/messaging_state.dart';

final messagingApiProvider = Provider<MessagingApi>((ref) {
  final client = ref.watch(dioClientProvider);
  return MessagingApi(client);
});

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepositoryImpl(ref.watch(messagingApiProvider), ref.watch(appCacheProvider));
});

final messagingProvider = StateNotifierProvider.autoDispose<MessagingNotifier, MessagingState>((ref) {
  return MessagingNotifier(
    ref.watch(messagingRepositoryProvider),
    ref.watch(socketClientProvider),
    ref.watch(appCacheProvider),
  );
});