import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/active_session.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import 'package:trabajo_hub/features/auth/providers/auth_provider.dart';
import 'package:trabajo_hub/features/notifications/providers/notifications_provider.dart';
import 'package:trabajo_hub/features/shifts/providers/shifts_provider.dart';
import 'package:trabajo_hub/features/visits/providers/visits_provider.dart';

import '../../notifications/presentation/notifications_screen.dart';
import '../../shifts/data/models/shift_assignment_model.dart';
import '../../shifts/presentation/marketplace_screen.dart';
import '../../shifts/presentation/my_shifts_screen.dart';
import '../../shifts/presentation/widgets/mini_marketplace_section.dart';
import '../../visits/data/models/visit_model.dart';
import '../../visits/presentation/visits_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isRunningTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      if (isRunningTest) return;

      ref.read(marketplaceProvider.notifier).load(refresh: true);
      ref.read(myShiftsProvider.notifier).load(refresh: true);
      ref.read(visitsProvider.notifier).load(refresh: true);
      ref.read(notificationsProvider.notifier).load(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final marketplaceState = ref.watch(marketplaceProvider);
    final myShiftsState = ref.watch(myShiftsProvider);
    final visitsState = ref.watch(visitsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 148,
            backgroundColor: accentColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Text(
                user?.nurseProfile?.firstName != null && user!.displayName.isNotEmpty
                    ? '${_greeting()}, ${user.nurseProfile?.firstName}'
                    : 'Dashboard',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              centerTitle: false,
              background: Container(
                decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
                padding: const EdgeInsets.fromLTRB(18, 80, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track shifts, visits, and updates in one place.',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today at a glance',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _GlanceCard(
                    assignments: myShiftsState.assignments,
                    visits: visitsState.visits,
                    unreadCount: unreadCount,
                  ),
                  const SizedBox(height: 16),
                  _SummaryGrid(
                    shiftsCount: marketplaceState.shifts.length,
                    acceptedCount: myShiftsState.assignments.length,
                    visitsCount: visitsState.visits.length,
                    unreadCount: unreadCount,
                  ),
                  const SizedBox(height: 16),
                  MiniMarketplaceSection()
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final int shiftsCount;
  final int acceptedCount;
  final int visitsCount;
  final int unreadCount;

  const _SummaryGrid({
    required this.shiftsCount,
    required this.acceptedCount,
    required this.visitsCount,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      children: [
        Row(
          spacing: 16,
          children: [
            _SummaryTile(
              title: 'Shift Marketplace',
              value: '$shiftsCount',
              icon: Icons.work_outline,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
              ),
            ),
            _SummaryTile(
              title: 'Active Assignments',
              value: '$acceptedCount',
              icon: Icons.check_circle_outline,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 1,)),
              ),
            ),
          ],
        ),
        Row(
          spacing: 16,
          children: [
            _SummaryTile(
              title: 'Visits',
              value: '$visitsCount',
              icon: Icons.route_outlined,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex:2)),
              ),
            ),
            _SummaryTile(
              title: 'Alerts',
              value: '$unreadCount',
              icon: unreadCount > 0 ? Icons.notifications_active : Icons.notifications_active_outlined,
              isAlert: unreadCount > 0,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            )
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isAlert;

  const _SummaryTile({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isAlert ? const Color(0xFFB2440C) : accentColor;
    final bg = isAlert ? const Color(0xFFFDF1EC) : Colors.white;
    final border = isAlert ? const Color(0xFFF0C9B8) :  accentColor.withOpacity(.5);

    return Expanded(child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: fg, size: 24),
                  if (onTap != null)
                    Icon(Icons.chevron_right, size: 18, color: fg.withOpacity(0.5)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isAlert ? fg : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF536C79))),
            ],
          ),
        ),
      ),
    ));
  }
}

class _GlanceCard extends StatelessWidget {
  final List<ShiftAssignmentModel> assignments;
  final List<VisitModel> visits;
  final int unreadCount;

  const _GlanceCard({
    required this.assignments,
    required this.visits,
    required this.unreadCount,
  });

  static const _primary = Color(0xFF0F6E56);
  static const _urgent = Color(0xFFB2440C);
  static const _muted = Color(0xFF536C79);

  ShiftAssignmentModel? get _nextAssignment {
    final now = DateTime.now();
    final upcoming = assignments
        .where((a) =>
    a.status != 'cancelled' &&
        a.shift?.scheduledStart != null &&
        a.shift!.scheduledStart.isAfter(now))
        .toList()
      ..sort((a, b) => a.shift!.scheduledStart.compareTo(b.shift!.scheduledStart));
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  VisitModel? get _nextVisit {
    final now = DateTime.now();
    final upcoming = visits
        .where((v) =>
    v.status == VisitStatus.scheduled &&
        v.shiftInfo != null &&
        v.shiftInfo!.scheduledStart.isAfter(now))
        .toList()
      ..sort((a, b) => a.shiftInfo!.scheduledStart.compareTo(b.shiftInfo!.scheduledStart));
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  List<VisitModel> get _needsAttention => visits
      .where((v) => v.overrideRequired || v.status == VisitStatus.flagged)
      .toList();

  @override
  Widget build(BuildContext context) {
    final nextAssignment = _nextAssignment;
    final nextVisit = _nextVisit;
    final hasNothingUpcoming = nextAssignment == null && nextVisit == null;
    final isEmpty = hasNothingUpcoming && assignments.isEmpty && visits.isEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _primary.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'At a Glance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unreadCount new',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (isEmpty)
            _GlanceRow(
              icon: Icons.explore_outlined,
              text: 'Nothing scheduled yet. Check the marketplace for open shifts.',
              muted: true,
            )
          else ...[
            if (nextAssignment != null)
              GestureDetector(
                  onTap: ()=>Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 1,))),
                  child:  _GlanceRow(
                icon: Icons.work_outline,
                text: 'Next shift: ${_formatRelative(nextAssignment.shift!.scheduledStart)}',
                highlight: true,
              ))
            else if (assignments.isNotEmpty)
              GestureDetector(
                  onTap: ()=>Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 1,))),
                  child:  _GlanceRow(
                icon: Icons.work_outline,
                text: '${assignments.length} active assignment${assignments.length == 1 ? '' : 's'}',
              )),

            if (nextVisit != null)
              GestureDetector(
                  onTap: ()=>Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 2,))),
                  child: _GlanceRow(
                icon: Icons.route_outlined,
                text: 'Next visit: ${_formatRelative(nextVisit.shiftInfo!.scheduledStart)}'
                    '${nextVisit.shiftInfo!.locationDisplay != '—' ? ' · ${nextVisit.shiftInfo!.locationDisplay}' : ''}',
                highlight: true,
              ))
            else if (visits.isNotEmpty)
              GestureDetector(
                  onTap: ()=>Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 2,))),
                  child:  _GlanceRow(
                icon: Icons.route_outlined,
                text: '${visits.length} recent visit${visits.length == 1 ? '' : 's'}',
              )),
          ],

          if (_needsAttention.isNotEmpty) ...[
            const SizedBox(height: 4),
            GestureDetector(
                onTap: ()=>Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 2,))),
                child:  _GlanceRow(
              icon: Icons.warning_amber_rounded,
              text: '${_needsAttention.length} visit${_needsAttention.length == 1 ? '' : 's'} '
                  'need${_needsAttention.length == 1 ? 's' : ''} attention',
              urgent: true,
            )),
          ],

          if (!isEmpty) ...[
            const SizedBox(height: 8),
            Divider(color: _muted.withOpacity(.12), height: 1),
            const SizedBox(height: 8),
          ],

          GestureDetector(
              onTap: ()=>Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              child: _GlanceRow(
            icon: unreadCount > 0 ? Icons.notifications_active : Icons.notifications_none,
            text: unreadCount > 0
                ? '$unreadCount unread notification${unreadCount == 1 ? '' : 's'} need attention'
                : 'You are all caught up with notifications',
            highlight: unreadCount > 0,
            muted: unreadCount == 0,
          )),
        ],
      ),
    );
  }
}

class _GlanceRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;
  final bool urgent;
  final bool muted;

  const _GlanceRow({
    required this.icon,
    required this.text,
    this.highlight = false,
    this.urgent = false,
    this.muted = false,
  });

  static const _primary = Color(0xFF0F6E56);
  static const _urgent = Color(0xFFB2440C);
  static const _mutedColor = Color(0xFF536C79);

  @override
  Widget build(BuildContext context) {
    final color = urgent ? _urgent : highlight ? _primary : _mutedColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: muted ? _mutedColor.withOpacity(.08) : color.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: muted ? _mutedColor : color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.3,
                color: muted ? _mutedColor : color,
                fontWeight: (highlight || urgent) ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _formatRelative(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dt.year, dt.month, dt.day);
  final diff = target.difference(today).inDays;

  final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  final time = '$hour:$minute $period';

  if (diff == 0) return 'Today, $time';
  if (diff == 1) return 'Tomorrow, $time';

  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  if (diff > 1 && diff < 7) return '${weekdays[dt.weekday - 1]}, $time';
  return '${months[dt.month - 1]} ${dt.day}, $time';
}
