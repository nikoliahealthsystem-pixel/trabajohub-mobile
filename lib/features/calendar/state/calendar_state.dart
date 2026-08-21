import '../data/models/calendar_event_model.dart';

const _sentinel = Object();

enum CalendarViewMode { month, week }

enum CalendarLoadStatus { initial, loading, success, error }

class CalendarState {
  final CalendarLoadStatus status;
  final String? errorMessage;

  // All fetched events keyed by UTC day
  final Map<DateTime, List<CalendarEventModel>> eventsByDay;

  // Currently selected day on the calendar
  final DateTime focusedDay;
  final DateTime? selectedDay;

  // Active type filters — all on by default
  final Set<CalendarEventType> activeTypes;

  final CalendarViewMode viewMode;

  // The event tapped to show in detail sheet
  final CalendarEventModel? detailEvent;

  CalendarState({
    this.status = CalendarLoadStatus.initial,
    this.errorMessage,
    this.eventsByDay = const {},
    DateTime? focusedDay,
    this.selectedDay,
    Set<CalendarEventType>? activeTypes,
    this.viewMode = CalendarViewMode.month,
    this.detailEvent,
  })  : focusedDay = focusedDay ?? DateTime.now(),
        activeTypes = activeTypes ??
            {
              CalendarEventType.shift,
              CalendarEventType.recurringShift,
              CalendarEventType.visit,
              CalendarEventType.credentialExpiry,
              CalendarEventType.invoiceDue,
              CalendarEventType.invoiceOverdue,
            };

  List<CalendarEventModel> eventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return eventsByDay[key] ?? [];
  }

  List<CalendarEventModel> get selectedDayEvents {
    if (selectedDay == null) return eventsForDay(focusedDay);
    return eventsForDay(selectedDay!);
  }

  CalendarState copyWith({
    CalendarLoadStatus? status,
    Object? errorMessage = _sentinel,
    Map<DateTime, List<CalendarEventModel>>? eventsByDay,
    DateTime? focusedDay,
    Object? selectedDay = _sentinel,
    Set<CalendarEventType>? activeTypes,
    CalendarViewMode? viewMode,
    Object? detailEvent = _sentinel,
  }) =>
      CalendarState(
        status: status ?? this.status,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
        eventsByDay: eventsByDay ?? this.eventsByDay,
        focusedDay: focusedDay ?? this.focusedDay,
        selectedDay:
        selectedDay == _sentinel ? this.selectedDay : selectedDay as DateTime?,
        activeTypes: activeTypes ?? this.activeTypes,
        viewMode: viewMode ?? this.viewMode,
        detailEvent:
        detailEvent == _sentinel ? this.detailEvent : detailEvent as CalendarEventModel?,
      );
}

// Hack to use DateTime.now() as a const default
class _NowPlaceholder implements DateTime {
  const _NowPlaceholder();
  // All DateTime interface members delegate to DateTime.now()
  @override
  dynamic noSuchMethod(Invocation i) => (DateTime.now() as dynamic)
      .noSuchMethod(i); // ignore: avoid_dynamic_calls
}