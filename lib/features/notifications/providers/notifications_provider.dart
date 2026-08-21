import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/cache/cache_provider.dart';
import '../../../core/network/dio_client.dart';
import '../data/notifications_api.dart';
import '../data/notifications_repository.dart';
import '../data/notifications_repository_impl.dart';
import '../state/notifications_notifier.dart';
import '../state/notifications_state.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(dioClientProvider));
});

final notificationsRepositoryProvider =
Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(ref.watch(notificationsApiProvider), ref.watch(appCacheProvider));
});

final notificationsProvider =
StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.watch(notificationsRepositoryProvider));
});

// Unread count — consumed by the bell button anywhere in the app
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});