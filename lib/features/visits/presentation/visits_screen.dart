import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../data/models/visit_model.dart';
import '../providers/visits_provider.dart';
import '../state/visits_state.dart';
import 'visit_detail_screen.dart';

class VisitsScreen extends ConsumerStatefulWidget {
  const VisitsScreen({super.key});

  @override
  ConsumerState<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends ConsumerState<VisitsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const Color _background = Color(0xFFF6F8FB);
  static const Color _heading = Color(0xFF101828);
  static const Color _body = Color(0xFF667085);
  static const Color _muted = Color(0xFF98A2B3);
  static const Color _border = Color(0xFFE4E7EC);

  static const List<String?> _statusOptions = [
    null,
    'SCHEDULED',
    'CHECKED_IN',
    'CHECKED_OUT',
    'VERIFIED',
    'FLAGGED',
    'OVERRIDE_REQUESTED',
    'OVERRIDE_APPROVED',
    'CANCELLED',
  ];

  static const List<String> _statusLabels = [
    'All',
    'Scheduled',
    'Active',
    'Checked out',
    'Verified',
    'Flagged',
    'In review',
    'Approved',
    'Cancelled',
  ];

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visitsProvider.notifier).load(refresh: true);
    });

    _scrollController.addListener(_onScroll);

    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();

      if (next == _searchQuery) return;

      setState(() {
        _searchQuery = next;
      });
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.pixels < position.maxScrollExtent - 240) {
      return;
    }

    final state = ref.read(visitsProvider);

    if (state.hasMore && state.status == VisitsLoadStatus.success) {
      ref.read(visitsProvider.notifier).load();
    }
  }

  Future<void> _refresh() {
    return ref.read(visitsProvider.notifier).load(refresh: true);
  }

  void _openVisit(VisitModel visit) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VisitDetailScreen(visitId: visit.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visitsProvider);
    final visibleVisits = _applyLocalSearch(state.visits);

    final scheduledCount = state.visits
        .where((visit) => visit.status == VisitStatus.scheduled)
        .length;

    final activeCount = state.visits.where(_isActiveVisit).length;

    final reviewCount = state.visits.where(_needsReview).length;

    final completedCount = state.visits.where((visit) {
      return visit.status == VisitStatus.checkedOut ||
          visit.status == VisitStatus.verified ||
          visit.status == VisitStatus.overrideApproved;
    }).length;

    final todayVisits = state.visits.where(_isVisitToday).toList();
    final todayActive = todayVisits.where(_isActiveVisit).length;
    final todayCompleted = todayVisits.where((visit) {
      return visit.checkOutTime != null ||
          visit.status == VisitStatus.checkedOut ||
          visit.status == VisitStatus.verified;
    }).length;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: accentColor,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeroHeader(state: state, reviewCount: reviewCount),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: _TodayOverview(
                    total: todayVisits.length,
                    active: todayActive,
                    completed: todayCompleted,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _buildSummaryGrid(
                    scheduled: scheduledCount,
                    active: activeCount,
                    completed: completedCount,
                    attention: reviewCount,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: _buildSearchField(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildFilters(state),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: _buildListHeading(
                    state: state,
                    visibleCount: visibleVisits.length,
                  ),
                ),
              ),
              ..._buildBodySlivers(state, visibleVisits),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader({
    required VisitsState state,
    required int reviewCount,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: ColorConstants.appGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset('assets/app_icon.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Visits',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.45,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your clinical schedule, EVV and visit history',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderAction(
                icon: Icons.calendar_month_outlined,
                tooltip: 'Open calendar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CalendarScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visit activity',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${state.total}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.9,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Total assigned visits',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    ref.read(visitsProvider.notifier).toggleFlaggedOnly();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: state.flaggedOnly
                          ? const Color(0xFFE5484D)
                          : Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.flaggedOnly
                              ? 'Review queue'
                              : reviewCount > 0
                              ? '$reviewCount need review'
                              : 'No EVV issues',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid({
    required int scheduled,
    required int active,
    required int completed,
    required int attention,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: _VisitMetricCard(
                label: 'Scheduled',
                value: scheduled,
                subtitle: 'Upcoming visits',
                icon: Icons.event_outlined,
                accent: const Color(0xFF175CD3),
              ),
            ),
            SizedBox(
              width: width,
              child: _VisitMetricCard(
                label: 'Active',
                value: active,
                subtitle: 'In progress now',
                icon: Icons.play_circle_outline_rounded,
                accent: const Color(0xFF7F56D9),
              ),
            ),
            SizedBox(
              width: width,
              child: _VisitMetricCard(
                label: 'Completed',
                value: completed,
                subtitle: 'Finished visits',
                icon: Icons.check_circle_outline_rounded,
                accent: const Color(0xFF027A48),
              ),
            ),
            SizedBox(
              width: width,
              child: _VisitMetricCard(
                label: 'Needs review',
                value: attention,
                subtitle: 'EVV attention',
                icon: Icons.warning_amber_rounded,
                accent: const Color(0xFFB54708),
                highlighted: attention > 0,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search case, visit type, city, state or status',
        hintStyle: const TextStyle(color: _muted, fontSize: 12.5),
        prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 21),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close_rounded, color: _muted),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentColor, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildFilters(VisitsState state) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = state.statusFilter == _statusOptions[index];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                ref
                    .read(visitsProvider.notifier)
                    .setStatusFilter(_statusOptions[index]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected ? accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: selected ? accentColor : _border),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: .15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _statusLabels[index],
                  style: TextStyle(
                    color: selected ? Colors.white : _body,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListHeading({
    required VisitsState state,
    required int visibleCount,
  }) {
    String title = 'All visits';

    if (state.flaggedOnly) {
      title = 'Needs EVV review';
    } else if (state.statusFilter != null) {
      final index = _statusOptions.indexOf(state.statusFilter);

      if (index >= 0) {
        title = _statusLabels[index];
      }
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _heading,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _searchQuery.isEmpty
                    ? '$visibleCount visit${visibleCount == 1 ? '' : 's'} shown · tap any card for full EVV details'
                    : '$visibleCount matching visit${visibleCount == 1 ? '' : 's'}',
                style: const TextStyle(color: _body, fontSize: 11.5),
              ),
            ],
          ),
        ),
        if (state.flaggedOnly || state.statusFilter != null)
          TextButton(
            onPressed: () {
              if (state.flaggedOnly) {
                ref.read(visitsProvider.notifier).toggleFlaggedOnly();
              }

              if (state.statusFilter != null) {
                ref.read(visitsProvider.notifier).setStatusFilter(null);
              }
            },
            child: Text(
              'Clear',
              style: TextStyle(
                color: accentColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildBodySlivers(VisitsState state, List<VisitModel> visits) {
    if (state.status == VisitsLoadStatus.loading && state.visits.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _VisitsLoadingState(),
        ),
      ];
    }

    if (state.status == VisitsLoadStatus.error && state.visits.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _VisitsErrorState(
            message: state.errorMessage ?? 'Failed to load visits',
            onRetry: _refresh,
          ),
        ),
      ];
    }

    if (visits.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _VisitsEmptyState(
            hasSearch: _searchQuery.isNotEmpty,
            onClearSearch: _searchController.clear,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList.builder(
          itemCount: visits.length,
          itemBuilder: (context, index) {
            final visit = visits[index];

            return _VisitCard(visit: visit, onTap: () => _openVisit(visit));
          },
        ),
      ),
      if (state.status == VisitsLoadStatus.loadingMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Center(
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 2.4,
              ),
            ),
          ),
        ),
    ];
  }

  List<VisitModel> _applyLocalSearch(List<VisitModel> visits) {
    if (_searchQuery.isEmpty) {
      return visits;
    }

    return visits.where((visit) {
      final shift = visit.shiftInfo;

      final searchable = [
        shift?.caseIdentifier,
        shift?.visitType,
        shift?.city,
        shift?.state,
        visit.status.label,
        visit.notes,
        visit.overrideReason,
      ].whereType<String>().join(' ').toLowerCase();

      return searchable.contains(_searchQuery);
    }).toList();
  }

  bool _isActiveVisit(VisitModel visit) {
    return visit.checkInTime != null &&
        visit.checkOutTime == null &&
        (visit.status == VisitStatus.checkedIn ||
            visit.status == VisitStatus.flagged ||
            visit.status == VisitStatus.overrideRequested ||
            visit.status == VisitStatus.overrideApproved);
  }

  bool _needsReview(VisitModel visit) {
    return visit.overrideRequired ||
        visit.status == VisitStatus.flagged ||
        visit.status == VisitStatus.overrideRequested;
  }

  bool _isVisitToday(VisitModel visit) {
    final shift = visit.shiftInfo;
    if (shift == null) return false;

    final now = DateTime.now();
    final start = shift.scheduledStart.toLocal();

    return start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
  }
}

class _TodayOverview extends StatelessWidget {
  final int total;
  final int active;
  final int completed;

  const _TodayOverview({
    required this.total,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.today_rounded, color: accentColor, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(now),
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'No visits scheduled for today'
                      : '$total today · $active active · $completed completed',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$total',
              style: TextStyle(
                color: accentColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}

class _VisitMetricCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final int value;
  final IconData icon;
  final Color accent;
  final bool highlighted;

  const _VisitMetricCard({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.accent,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFFAEB) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFFEDFA8)
              : const Color(0xFFE4E7EC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: accent,
                    fontSize: 21,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final VisitModel visit;
  final VoidCallback onTap;

  const _VisitCard({required this.visit, required this.onTap});

  static const _statusColors = {
    VisitStatus.scheduled: (Color(0xFFEFF8FF), Color(0xFF175CD3)),
    VisitStatus.checkedIn: (Color(0xFFF4F3FF), Color(0xFF6941C6)),
    VisitStatus.checkedOut: (Color(0xFFECFDF3), Color(0xFF027A48)),
    VisitStatus.verified: (Color(0xFFECFDF3), Color(0xFF027A48)),
    VisitStatus.flagged: (Color(0xFFFEF3F2), Color(0xFFB42318)),
    VisitStatus.overrideRequested: (Color(0xFFFFFAEB), Color(0xFFB54708)),
    VisitStatus.overrideApproved: (Color(0xFFECFDF3), Color(0xFF027A48)),
    VisitStatus.cancelled: (Color(0xFFFEF3F2), Color(0xFFB42318)),
  };

  @override
  Widget build(BuildContext context) {
    final colors =
        _statusColors[visit.status] ?? _statusColors[VisitStatus.scheduled]!;

    final shift = visit.shiftInfo;
    final displayVisitType = _titleCase(shift?.visitType ?? 'Visit');

    final location = shift?.locationDisplay ?? 'Location unavailable';

    final scheduled = shift != null
        ? _formatVisitSchedule(shift.scheduledStart, shift.scheduledEnd)
        : 'Schedule unavailable';

    final requiresAttention = _requiresAttention(visit);
    final active = _isActive(visit);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: requiresAttention
                    ? const Color(0xFFFECACA)
                    : active
                    ? const Color(0xFFD9D6FE)
                    : const Color(0xFFE4E7EC),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x07101828),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (active)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F3FF),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(21),
                      ),
                    ),
                    child: const Row(
                      children: [
                        _LiveDot(),
                        SizedBox(width: 7),
                        Text(
                          'VISIT IN PROGRESS',
                          style: TextStyle(
                            color: Color(0xFF6941C6),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 47,
                            height: 47,
                            decoration: BoxDecoration(
                              color: colors.$1,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _visitStatusIcon(visit.status),
                              color: colors.$2,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayVisitType,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF101828),
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.2,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  shift?.caseIdentifier != null
                                      ? shift!.caseIdentifier!
                                      : 'Visit record',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF98A2B3),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _VisitStatusBadge(
                            status: visit.status,
                            background: colors.$1,
                            foreground: colors.$2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _VisitInfoLine(
                        icon: Icons.calendar_today_outlined,
                        text: scheduled,
                        emphasized: true,
                      ),
                      const SizedBox(height: 9),
                      _VisitInfoLine(
                        icon: Icons.location_on_outlined,
                        text: location,
                      ),
                      if (visit.checkInTime != null) ...[
                        const SizedBox(height: 9),
                        _VisitInfoLine(
                          icon: Icons.login_rounded,
                          text:
                              'Checked in ${DateFormat('MMM d · h:mm a').format(visit.checkInTime!.toLocal())}',
                        ),
                      ],
                      if (visit.checkOutTime != null) ...[
                        const SizedBox(height: 9),
                        _VisitInfoLine(
                          icon: Icons.logout_rounded,
                          text:
                              'Checked out ${DateFormat('MMM d · h:mm a').format(visit.checkOutTime!.toLocal())}',
                        ),
                      ],
                      if (visit.durationMinutes != null) ...[
                        const SizedBox(height: 9),
                        _VisitInfoLine(
                          icon: Icons.timer_outlined,
                          text:
                              '${_formatDuration(visit.durationMinutes!)} recorded duration',
                        ),
                      ],
                      if (requiresAttention) ...[
                        const SizedBox(height: 15),
                        _ReviewNotice(
                          message:
                              visit.overrideReason ??
                              'This visit requires EVV review before the attendance record is finalized.',
                        ),
                      ],
                      if (visit.notes != null &&
                          visit.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.notes_rounded,
                                color: Color(0xFF98A2B3),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  visit.notes!.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF667085),
                                    fontSize: 10.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.only(top: 13),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFF2F4F7)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _visitActionLabel(visit),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: accentColor,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _isActive(VisitModel visit) {
    if (visit.status == VisitStatus.cancelled) {
      return false;
    }

    return visit.checkInTime != null &&
        visit.checkOutTime == null &&
        (visit.status == VisitStatus.checkedIn ||
            visit.status == VisitStatus.flagged ||
            visit.status == VisitStatus.overrideRequested ||
            visit.status == VisitStatus.overrideApproved);
  }

  static bool _requiresAttention(VisitModel visit) {
    return visit.overrideRequired ||
        visit.status == VisitStatus.flagged ||
        visit.status == VisitStatus.overrideRequested;
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF7F56D9),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ReviewNotice extends StatelessWidget {
  final String message;

  const _ReviewNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEB),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFEDFA8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.fact_check_outlined,
            color: Color(0xFFB54708),
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EVV review required',
                  style: TextStyle(
                    color: Color(0xFF934A0A),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF934A0A),
                    fontSize: 10.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitStatusBadge extends StatelessWidget {
  final VisitStatus status;
  final Color background;
  final Color foreground;

  const _VisitStatusBadge({
    required this.status,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 105),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusDisplayLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VisitInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool emphasized;

  const _VisitInfoLine({
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: emphasized ? const Color(0xFF475467) : const Color(0xFF98A2B3),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emphasized
                  ? const Color(0xFF475467)
                  : const Color(0xFF667085),
              fontSize: 11.5,
              height: 1.35,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisitsLoadingState extends StatelessWidget {
  const _VisitsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            height: 180,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisitsErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _VisitsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Color(0xFFB42318),
                size: 28,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load visits',
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 17),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: accentColor),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitsEmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onClearSearch;

  const _VisitsEmptyState({
    required this.hasSearch,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F4F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_outlined,
                color: Color(0xFF667085),
                size: 29,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              hasSearch ? 'No matching visits' : 'No visits here yet',
              style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasSearch
                  ? 'Try another case number, location, visit type or status.'
                  : 'Assigned visits will appear here with schedule and EVV details.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                height: 1.45,
              ),
            ),
            if (hasSearch) ...[
              const SizedBox(height: 13),
              TextButton(
                onPressed: onClearSearch,
                child: Text(
                  'Clear search',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

IconData _visitStatusIcon(VisitStatus status) {
  switch (status) {
    case VisitStatus.scheduled:
      return Icons.event_outlined;

    case VisitStatus.checkedIn:
      return Icons.play_circle_outline_rounded;

    case VisitStatus.checkedOut:
      return Icons.logout_rounded;

    case VisitStatus.verified:
      return Icons.verified_outlined;

    case VisitStatus.flagged:
      return Icons.flag_outlined;

    case VisitStatus.overrideRequested:
      return Icons.fact_check_outlined;

    case VisitStatus.overrideApproved:
      return Icons.check_circle_outline_rounded;

    case VisitStatus.cancelled:
      return Icons.cancel_outlined;
  }
}

String _visitActionLabel(VisitModel visit) {
  final active = visit.checkInTime != null && visit.checkOutTime == null;

  if (active && visit.status != VisitStatus.cancelled) {
    return visit.overrideRequired
        ? 'Continue visit · EVV review pending'
        : 'Continue active visit';
  }

  switch (visit.status) {
    case VisitStatus.scheduled:
      return 'Open visit & prepare for check-in';

    case VisitStatus.checkedIn:
      return 'Continue active visit';

    case VisitStatus.checkedOut:
      return 'Review completed visit';

    case VisitStatus.verified:
      return 'View verified visit & earnings';

    case VisitStatus.flagged:
      return 'Open visit · EVV attention required';

    case VisitStatus.overrideRequested:
      return 'View EVV review status';

    case VisitStatus.overrideApproved:
      return visit.checkOutTime != null
          ? 'View approved visit'
          : 'Continue approved visit';

    case VisitStatus.cancelled:
      return 'View cancelled visit';
  }
}

String _statusDisplayLabel(VisitStatus status) {
  switch (status) {
    case VisitStatus.scheduled:
      return 'SCHEDULED';

    case VisitStatus.checkedIn:
      return 'ACTIVE';

    case VisitStatus.checkedOut:
      return 'CHECKED OUT';

    case VisitStatus.verified:
      return 'VERIFIED';

    case VisitStatus.flagged:
      return 'FLAGGED';

    case VisitStatus.overrideRequested:
      return 'IN REVIEW';

    case VisitStatus.overrideApproved:
      return 'APPROVED';

    case VisitStatus.cancelled:
      return 'CANCELLED';
  }
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatVisitSchedule(DateTime start, DateTime end) {
  final localStart = start.toLocal();
  final localEnd = end.toLocal();

  final day = DateFormat('EEE, MMM d').format(localStart);

  final startTime = DateFormat('h:mm a').format(localStart);

  final endTime = DateFormat('h:mm a').format(localEnd);

  return '$day · $startTime – $endTime';
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;

  if (hours == 0) {
    return '$remaining min';
  }

  if (remaining == 0) {
    return '${hours}h';
  }

  return '${hours}h ${remaining}m';
}
