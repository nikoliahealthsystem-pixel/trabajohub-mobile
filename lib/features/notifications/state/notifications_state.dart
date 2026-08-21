import '../data/models/notification_model.dart';

const _sentinel = Object();

enum NotificationsStatus { initial, loading, loadingMore, success, error }

class NotificationsState {
  final NotificationsStatus status;
  final List<NotificationModel> items;
  final int total;
  final bool hasMore;
  final int page;
  final bool unreadOnly;
  final bool isMarkingAll;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.page = 1,
    this.unreadOnly = false,
    this.isMarkingAll = false,
    this.errorMessage,
  });

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationModel>? items,
    int? total,
    bool? hasMore,
    int? page,
    bool? unreadOnly,
    bool? isMarkingAll,
    Object? errorMessage = _sentinel,
  }) =>
      NotificationsState(
        status: status ?? this.status,
        items: items ?? this.items,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        unreadOnly: unreadOnly ?? this.unreadOnly,
        isMarkingAll: isMarkingAll ?? this.isMarkingAll,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
      );
}