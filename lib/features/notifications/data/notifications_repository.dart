import 'models/notification_model.dart';
import 'models/notification_preferences_model.dart';

abstract class NotificationsRepository {
  Future<({List<NotificationModel> items, int total, bool hasMore})>
  getNotifications({int page, int limit, bool unreadOnly});

  Future<int> getUnreadCount();

  Future<void> markOneRead(String id);

  Future<void> markAllRead();

  Future<NotificationPreferencesModel> getPreferences();

  Future<NotificationPreferencesModel> updatePreferences(
    Map<String, bool> updates,
  );
}
