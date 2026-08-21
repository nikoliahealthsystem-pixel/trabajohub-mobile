import 'models/notification_model.dart';

abstract class NotificationsRepository {
  Future<({List<NotificationModel> items, int total, bool hasMore})>
  getNotifications({int page, int limit, bool unreadOnly});

  Future<void> markOneRead(String id);
  Future<void> markAllRead();
}