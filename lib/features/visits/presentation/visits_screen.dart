import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
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
  final _scrollController = ScrollController();

  static const _statusOptions = [
    null, 'SCHEDULED', 'CHECKED_IN', 'CHECKED_OUT', 'VERIFIED', 'FLAGGED',
  ];
  static const _statusLabels = [
    'All', 'Scheduled', 'Checked In', 'Checked Out', 'Verified', 'Flagged',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visitsProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final s = ref.read(visitsProvider);
      if (s.hasMore && s.status == VisitsLoadStatus.success) {
        ref.read(visitsProvider.notifier).load();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visitsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(context, state),
          _buildFilters(state),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, VisitsState state) =>
      Container(
        decoration: const BoxDecoration(
          gradient: ColorConstants.appGradient,
        ),
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 14, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Visit History',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                  Text('${state.total} visits',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            // Flagged toggle
            GestureDetector(
              onTap: () =>
                  ref.read(visitsProvider.notifier).toggleFlaggedOnly(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: state.flaggedOnly
                      ? const Color(0xFFEF4444)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    const Text('Flagged',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12,),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CalendarScreen())),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: state.flaggedOnly
                      ? const Color(0xFFEF4444)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  'assets/svg/calender.svg',
                  width: 28,
                  height: 28,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      );

  Widget _buildFilters(VisitsState state) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_statusOptions.length, (i) {
          final isActive =
              state.statusFilter == _statusOptions[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref
                  .read(visitsProvider.notifier)
                  .setStatusFilter(_statusOptions[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFEAF8FC)
                      : const Color(0xFFF0F4F7),
                  border: Border.all(
                      color: isActive
                          ? accentColor
                          : const Color(0xFFE2E8ED)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabels[i],
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF0A7D95)
                          : const Color(0xFF536C79)),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );

  Widget _buildBody(VisitsState state) {
    if (state.status == VisitsLoadStatus.loading) {
      return Center(
          child: CircularProgressIndicator(color: accentColor));
    }
    if (state.status == VisitsLoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Color(0xFFE24B4A)),
            const SizedBox(height: 12),
            Text(state.errorMessage ?? 'Failed to load visits'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(visitsProvider.notifier).load(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.visits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined,
                size: 52, color: Color(0xFF94A3B4)),
            SizedBox(height: 12),
            Text('No visits found',
                style: TextStyle(color: Color(0xFF536C79))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () =>
          ref.read(visitsProvider.notifier).load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: state.visits.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= state.visits.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(
                      color: accentColor)),
            );
          }
          return _VisitTile(
            visit: state.visits[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      VisitDetailScreen(visitId: state.visits[i].id)),
            ),
          );
        },
      ),
    );
  }
}

// ── Visit tile ──────────────────────────────────────────────────

class _VisitTile extends StatelessWidget {
  final VisitModel visit;
  final VoidCallback onTap;
  const _VisitTile({required this.visit, required this.onTap});

  static const _statusColors = {
    VisitStatus.scheduled: (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    VisitStatus.checkedIn: (Color(0xFFEDE9FE), Color(0xFF6D28D9)),
    VisitStatus.checkedOut: (Color(0xFFDCFCE7), Color(0xFF15803D)),
    VisitStatus.verified: (Color(0xFFE1F5EE), Color(0xFF0F6E56)),
    VisitStatus.flagged: (Color(0xFFFCEBEB), Color(0xFFB91C1C)),
    VisitStatus.overrideRequested: (Color(0xFFFEF3C7), Color(0xFFB45309)),
    VisitStatus.overrideApproved: (Color(0xFFDCFCE7), Color(0xFF15803D)),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors[visit.status] ??
        _statusColors[VisitStatus.scheduled]!;
    final tf = DateFormat('MMM d · h:mm a');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          children: [
            Container(
              height: 3,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: colors.$2,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: colors.$1,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.medical_information_outlined,
                        color: colors.$2, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (visit.shiftInfo?.caseIdentifier != null)
                              Text(
                                visit.shiftInfo!.caseIdentifier!,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B4),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4),
                              ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.$1,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(visit.status.label,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: colors.$2)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          visit.shiftInfo?.visitType
                              .replaceAll('_', ' ') ??
                              'Visit',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A2632)),
                        ),
                        const SizedBox(height: 4),
                        if (visit.checkInTime != null)
                          Row(
                            children: [
                              const Icon(Icons.login_rounded,
                                  size: 12, color: Color(0xFF94A3B4)),
                              const SizedBox(width: 4),
                              Text(
                                'In: ${tf.format(visit.checkInTime!)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF536C79)),
                              ),
                            ],
                          ),
                        if (visit.checkOutTime != null)
                          Row(
                            children: [
                              const Icon(Icons.logout_rounded,
                                  size: 12, color: Color(0xFF94A3B4)),
                              const SizedBox(width: 4),
                              Text(
                                'Out: ${tf.format(visit.checkOutTime!)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF536C79)),
                              ),
                            ],
                          ),
                        if (visit.durationMinutes != null)
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 12, color: Color(0xFF94A3B4)),
                              const SizedBox(width: 4),
                              Text('${visit.durationMinutes} min',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF536C79))),
                            ],
                          ),
                        if (visit.overrideRequired)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 12,
                                    color: Color(0xFFB45309)),
                                const SizedBox(width: 4),
                                const Text('Override required',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFB45309),
                                        fontWeight:
                                        FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}