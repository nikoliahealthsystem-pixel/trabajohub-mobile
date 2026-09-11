import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'models/notification_model.dart';
import 'models/notification_preferences_model.dart';
import 'notifications_api.dart';
import 'notifications_repository.dart';

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

    if (cached != null && !cached.isStale) {
      return cached.data;
    }

    final raw = await _api.fetchNotifications(
      page: page,
      limit: limit,
      unreadOnly: unreadOnly,
    );

    final data = raw['data'] as List? ?? const [];

    final pagination = Map<String, dynamic>.from(raw['pagination'] ?? const {});

    final result = (
      items: data
          .map(
            (json) => NotificationModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList(),
      total: (pagination['total'] as num?)?.toInt() ?? 0,
      hasMore: pagination['hasNext'] == true,
    );

    _cache.set(key, result, CacheTtl.notifications);

    return result;
  }

  @override
  Future<int> getUnreadCount() {
    return _api.fetchUnreadCount();
  }

  @override
  Future<void> markOneRead(String id) async {
    await _api.markOneRead(id);

    _cache.invalidatePrefix(CacheKeys.prefixNotifications);
  }

  @override
  Future<void> markAllRead() async {
    await _api.markAllRead();

    _cache.invalidatePrefix(CacheKeys.prefixNotifications);
  }

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    final raw = await _api.fetchPreferences();

    final data = Map<String, dynamic>.from(raw['data'] ?? const {});

    return NotificationPreferencesModel.fromJson(data);
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences(
    Map<String, bool> updates,
  ) async {
    final raw = await _api.updatePreferences(updates);

    final data = Map<String, dynamic>.from(raw['data'] ?? const {});

    return NotificationPreferencesModel.fromJson(data);
  }
}
