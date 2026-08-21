import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      state = state.copyWith(
        status: NotificationsStatus.success,
        items: [...(refresh ? [] : state.items), ...result.items],
        total: result.total,
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
    // Optimistic update
    state = state.copyWith(
      items: state.items
          .map((n) => n.id == id
          ? n.copyWith(isRead: true, readAt: DateTime.now())
          : n)
          .toList(),
    );
    try {
      await _repo.markOneRead(id);
    } catch (_) {
      // Rollback on failure
      state = state.copyWith(
        items: state.items
            .map((n) => n.id == id ? n.copyWith(isRead: false) : n)
            .toList(),
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
        items: state.items
            .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
            .toList(),
      );
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(
        isMarkingAll: false,
        errorMessage: message,
      );
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}