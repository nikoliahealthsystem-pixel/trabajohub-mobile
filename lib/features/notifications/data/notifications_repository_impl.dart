import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'notifications_api.dart';
import 'notifications_repository.dart';
import 'models/notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsApi _api;
  final AppCache _cache;
  NotificationsRepositoryImpl(this._api, this._cache);

  @override
  Future<({List<NotificationModel> items, int total, bool hasMore})>
  getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final key = CacheKeys.notifications(page: page, unreadOnly: unreadOnly);
    final cached = _cache
        .get<({List<NotificationModel> items, int total, bool hasMore})>(key);

    if (cached != null && !cached.isStale) return cached.data;

    final raw = await _api.fetchNotifications(
        page: page, limit: limit, unreadOnly: unreadOnly);
    final data = raw['data'] as List? ?? [];
    final pagination = raw['pagination'] as Map<String, dynamic>? ?? {};
    final result = (
    items: data.map((j) => NotificationModel.fromJson(j)).toList(),
    total: pagination['total'] as int? ?? 0,
    hasMore: pagination['hasNext'] as bool? ?? false,
    );
    _cache.set(key, result, CacheTtl.notifications);
    return result;
  }

  @override
  Future<void> markOneRead(String id) async {
    await _api.markOneRead(id);
    // Invalidate all notification pages + unread count
    _cache.invalidatePrefix(CacheKeys.prefixNotifications);
  }

  @override
  Future<void> markAllRead() async {
    await _api.markAllRead();
    _cache.invalidatePrefix(CacheKeys.prefixNotifications);
  }
}