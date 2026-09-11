import '../data/models/notification_model.dart';

const _sentinel = Object();

enum NotificationsStatus { initial, loading, loadingMore, success, error }

class NotificationsState {
  final NotificationsStatus status;
  final List<NotificationModel> items;
  final int total;
  final int unreadCount;
  final bool hasMore;
  final int page;
  final bool unreadOnly;
  final bool isMarkingAll;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.total = 0,
    this.unreadCount = 0,
    this.hasMore = false,
    this.page = 1,
    this.unreadOnly = false,
    this.isMarkingAll = false,
    this.errorMessage,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationModel>? items,
    int? total,
    int? unreadCount,
    bool? hasMore,
    int? page,
    bool? unreadOnly,
    bool? isMarkingAll,
    Object? errorMessage = _sentinel,
  }) => NotificationsState(
    status: status ?? this.status,
    items: items ?? this.items,
    total: total ?? this.total,
    unreadCount: unreadCount ?? this.unreadCount,
    hasMore: hasMore ?? this.hasMore,
    page: page ?? this.page,
    unreadOnly: unreadOnly ?? this.unreadOnly,
    isMarkingAll: isMarkingAll ?? this.isMarkingAll,
    errorMessage: errorMessage == _sentinel
        ? this.errorMessage
        : errorMessage as String?,
  );
}
