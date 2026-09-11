import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repo;
  NotificationsNotifier(this._repo) : super(const NotificationsState());

  // ── Load / refresh ─────────────────────────────────────────

  Future<void> load({bool refresh = false}) async {
    if (state.status == NotificationsStatus.loading) return;

    final page = refresh ? 1 : state.page;
    final isFirst = refresh || state.items.isEmpty;

    state = state.copyWith(
      status: isFirst
          ? NotificationsStatus.loading
          : NotificationsStatus.loadingMore,
      items: refresh ? [] : state.items,
    );

    try {
      final result = await _repo.getNotifications(
        page: page,
        unreadOnly: state.unreadOnly,
      );

      final unreadCount = await _repo.getUnreadCount();

      state = state.copyWith(
        status: NotificationsStatus.success,
        items: [...(refresh ? [] : state.items), ...result.items],
        total: result.total,
        unreadCount: unreadCount,
        hasMore: result.hasMore,
        page: page + 1,
      );
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: message,
      );
    }
  }

  // ── Filter toggle ──────────────────────────────────────────

  Future<void> toggleUnreadOnly() async {
    state = state.copyWith(unreadOnly: !state.unreadOnly);
    await load(refresh: true);
  }

  // ── Mark one read ──────────────────────────────────────────

  Future<void> markOneRead(String id) async {
    final existing = state.items
        .where((n) => n.id == id)
        .cast<dynamic>()
        .firstWhere((n) => n != null, orElse: () => null);

    if (existing == null || existing.isRead == true) {
      return;
    }

    final previousItems = state.items;
    final previousUnreadCount = state.unreadCount;
    final previousTotal = state.total;

    final updatedItems = state.unreadOnly
        ? state.items.where((n) => n.id != id).toList()
        : state.items
              .map(
                (n) => n.id == id
                    ? n.copyWith(isRead: true, readAt: DateTime.now())
                    : n,
              )
              .toList();

    state = state.copyWith(
      items: updatedItems,
      unreadCount: previousUnreadCount > 0 ? previousUnreadCount - 1 : 0,
      total: state.unreadOnly && previousTotal > 0
          ? previousTotal - 1
          : previousTotal,
    );

    try {
      await _repo.markOneRead(id);
    } catch (_) {
      state = state.copyWith(
        items: previousItems,
        unreadCount: previousUnreadCount,
        total: previousTotal,
      );
    }
  }

  // ── Mark all read ──────────────────────────────────────────

  Future<void> markAllRead() async {
    state = state.copyWith(isMarkingAll: true);
    try {
      await _repo.markAllRead();
      state = state.copyWith(
        isMarkingAll: false,
        unreadCount: 0,
        items: state.unreadOnly
            ? []
            : state.items
                  .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
                  .toList(),
        total: state.unreadOnly ? 0 : state.total,
      );
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isMarkingAll: false, errorMessage: message);
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}
