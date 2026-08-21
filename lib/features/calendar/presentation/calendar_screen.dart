import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import '../data/models/calendar_event_model.dart';
import '../providers/calendar_provider.dart';
import '../state/calendar_notifier.dart';
import '../state/calendar_state.dart';
import 'widgets/calendar_event_dot.dart';
import 'widgets/event_detail_sheet.dart';
import 'widgets/event_type_filter_bar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // Track the last loaded range to avoid duplicate fetches
  DateTime? _lastLoadedFrom;
  DateTime? _lastLoadedTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForCurrentMonth(DateTime.now());
    });
  }

  void _loadForCurrentMonth(DateTime day) {
    final from = DateTime.utc(day.year, day.month, 1);
    final to = DateTime.utc(day.year, day.month + 1, 0, 23, 59, 59);
    if (from == _lastLoadedFrom && to == _lastLoadedTo) return;
    _lastLoadedFrom = from;
    _lastLoadedTo = to;
    ref.read(calendarProvider.notifier).loadEvents(from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, state),
          EventTypeFilterBar(
            activeTypes: state.activeTypes,
            onToggle: (type) {
              notifier.toggleType(type);
              _lastLoadedFrom = null; // force reload
              _loadForCurrentMonth(state.focusedDay);
            },
            onReset: () {
              notifier.resetFilters();
              _lastLoadedFrom = null;
              _loadForCurrentMonth(state.focusedDay);
            },
          ),
          if (state.status == CalendarLoadStatus.error && state.errorMessage != null)
            _buildErrorBanner(state.errorMessage!, notifier),
          _buildCalendar(state, notifier),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),
          Expanded(child: _buildEventList(state)),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, CalendarState state) {
    return Container(
      decoration:  BoxDecoration(
        gradient: ColorConstants.appGradient,
      ),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 14, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calendar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text('Your schedule at a glance',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          // View toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: CalendarViewMode.values.map((mode) {
                final isActive = ref.watch(calendarProvider).viewMode == mode;
                return GestureDetector(
                  onTap: () =>
                      ref.read(calendarProvider.notifier).setViewMode(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      mode.name[0].toUpperCase() + mode.name.substring(1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error banner ───────────────────────────────────────────

  Widget _buildErrorBanner(String message, CalendarNotifier notifier) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF09595)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 14, color: Color(0xFFA32D2D)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message.length < 20 ? message : "Error Fetching Calender",
                  style: const TextStyle(fontSize: 12, color: Color(0xFFA32D2D))),
            ),
            GestureDetector(
              onTap: notifier.clearError,
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Color(0xFFA32D2D)),
            ),
          ],
        ),
      );

  // ── Table Calendar ─────────────────────────────────────────

  Widget _buildCalendar(CalendarState state, CalendarNotifier notifier) {
    final calendarFormat = state.viewMode == CalendarViewMode.month
        ? CalendarFormat.month : CalendarFormat.week;

    return Container(
      color: Colors.white,
      child: TableCalendar<CalendarEventModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: state.focusedDay,
        selectedDayPredicate: (day) => isSameDay(state.selectedDay, day),
        calendarFormat: calendarFormat,
        eventLoader: (day) => state.eventsForDay(day),
        startingDayOfWeek: StartingDayOfWeek.monday,

        // Navigation — reload events when month changes
        onPageChanged: (focusedDay) {
          notifier.setFocusedDay(focusedDay);
          _loadForCurrentMonth(focusedDay);
        },

        onDaySelected: (selectedDay, focusedDay) {
          notifier.selectDay(selectedDay, focusedDay);
        },

        // ── Styles ──────────────────────────────────────────
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A2632),
          ),
          leftChevronIcon:
          Icon(Icons.chevron_left_rounded, color: Color(0xFF536C79)),
          rightChevronIcon:
          Icon(Icons.chevron_right_rounded, color: Color(0xFF536C79)),
        ),

        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          todayTextStyle:
          TextStyle(color: accentColor, fontWeight: FontWeight.w700),
          selectedDecoration: BoxDecoration(
            gradient: ColorConstants.appGradient,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
          weekendTextStyle: const TextStyle(color: Color(0xFF94A3B4)),
          defaultTextStyle: const TextStyle(color: Color(0xFF1A2632)),
          markerDecoration: const BoxDecoration(
            color: Colors.transparent, // we render custom markers
          ),
          markersMaxCount: 4,
        ),

        // Custom marker builder — coloured dots
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events
                    .take(4)
                    .map((e) => CalendarEventDot(event: e))
                    .toList(),
              ),
            );
          },
          // Loading indicator on days being fetched
          todayBuilder: (context, day, focusedDay) {
            return Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style:   TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Event list for selected day ────────────────────────────

  Widget _buildEventList(CalendarState state) {
    final events = state.selectedDayEvents;
    final selectedLabel = state.selectedDay != null
        ? DateFormat('EEEE, MMMM d').format(state.selectedDay!)
        : DateFormat('EEEE, MMMM d').format(state.focusedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Text(
                selectedLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2632),
                ),
              ),
              const SizedBox(width: 8),
              if (state.status == CalendarLoadStatus.loading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: accentColor),
                ),
              const Spacer(),
              Text(
                '${events.length} event${events.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B4)),
              ),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available_outlined,
                    size: 36, color: Color(0xFF94A3B4)),
                SizedBox(height: 8),
                Text('No events on this day',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF94A3B4))),
              ],
            ),
          )
              : ListView.builder(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: events.length,
            itemBuilder: (_, i) =>
                _EventListTile(event: events[i]),
          ),
        ),
      ],
    );
  }
}

// ── Event list tile ────────────────────────────────────────────

class _EventListTile extends ConsumerWidget {
  final CalendarEventModel event;
  const _EventListTile({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = hexToColor(event.colorHex);
    final timeFormat = DateFormat('h:mm a');

    return GestureDetector(
      onTap: () {
        ref.read(calendarProvider.notifier).openDetail(event);
        EventDetailSheet.show(
          context,
          event,
              () => ref.read(calendarProvider.notifier).closeDetail(),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EDF2)),
          // Left accent bar
          gradient: LinearGradient(
            colors: [color.withOpacity(0.08), Colors.white],
            stops: const [0.0, 0.08],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            // Colour bar
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Emoji
            Text(event.type.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2632),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        event.allDay
                            ? 'All day'
                            : timeFormat.format(event.start),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B4)),
                      ),
                      if (!event.allDay && event.end != null) ...[
                        const Text(' – ',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF94A3B4))),
                        Text(
                          timeFormat.format(event.end!),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B4)),
                        ),
                      ],
                      const SizedBox(width: 8),
                      if (event.meta.location != null) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: Color(0xFF94A3B4)),
                        Flexible(
                          child: Text(
                            event.meta.location!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF94A3B4)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status dot
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                event.status.replaceAll('_', ' '),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}