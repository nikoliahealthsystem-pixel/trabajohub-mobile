import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/calendar_repository.dart';
import '../data/models/calendar_event_model.dart';
import 'calendar_state.dart';

class CalendarNotifier extends StateNotifier<CalendarState> {
  final CalendarRepository _repo;

  CalendarNotifier(this._repo) : super(CalendarState());

  // ── Load events for a visible range ───────────────────────

  Future<void> loadEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    state = state.copyWith(status: CalendarLoadStatus.loading, errorMessage: null);
    try {
      final activeList = state.activeTypes.isEmpty
          ? null
          : state.activeTypes.toList();

      final events = await _repo.getEvents(
        from: from,
        to: to,
        types: activeList,
      );

      // Group by UTC day key
      final Map<DateTime, List<CalendarEventModel>> grouped = {};
      for (final event in events) {
        grouped.putIfAbsent(event.dayKey, () => []).add(event);
      }

      state = state.copyWith(
        status: CalendarLoadStatus.success,
        eventsByDay: grouped,
      );
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(
        status: CalendarLoadStatus.error,
        errorMessage: message,
      );
    }
  }

  // ── Day selection ──────────────────────────────────────────

  void selectDay(DateTime day, DateTime focused) {
    state = state.copyWith(
      selectedDay: day,
      focusedDay: focused,
    );
  }

  void setFocusedDay(DateTime day) {
    state = state.copyWith(focusedDay: day);
  }

  // ── View mode ──────────────────────────────────────────────

  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  // ── Type filter ────────────────────────────────────────────

  void toggleType(CalendarEventType type) {
    final current = Set<CalendarEventType>.from(state.activeTypes);
    if (current.contains(type)) {
      if (current.length > 1) current.remove(type);
    } else {
      current.add(type);
    }
    state = state.copyWith(activeTypes: current);
  }

  void resetFilters() {
    state = state.copyWith(
      activeTypes: {
        CalendarEventType.shift,
        CalendarEventType.recurringShift,
        CalendarEventType.visit,
        CalendarEventType.credentialExpiry,
        CalendarEventType.invoiceDue,
        CalendarEventType.invoiceOverdue,
      },
    );
  }

  // ── Detail sheet ───────────────────────────────────────────

  void openDetail(CalendarEventModel event) {
    state = state.copyWith(detailEvent: event);
  }

  void closeDetail() {
    state = state.copyWith(detailEvent: null);
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}