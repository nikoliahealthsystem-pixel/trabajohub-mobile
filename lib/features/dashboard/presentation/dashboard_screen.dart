import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/active_session.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import 'package:trabajo_hub/features/auth/providers/auth_provider.dart';
import 'package:trabajo_hub/features/billing/presentation/widgets/wallet_card.dart';
import 'package:trabajo_hub/features/billing/providers/billing_provider.dart';
import 'package:trabajo_hub/features/billing/state/billing_state.dart';
import 'package:trabajo_hub/features/notifications/providers/notifications_provider.dart';
import 'package:trabajo_hub/features/shifts/providers/shifts_provider.dart';
import 'package:trabajo_hub/features/visits/providers/visits_provider.dart';

import '../../notifications/presentation/notifications_screen.dart';
import '../../shifts/data/models/shift_assignment_model.dart';
import '../../shifts/presentation/marketplace_screen.dart';
import '../../shifts/presentation/widgets/mini_marketplace_section.dart';
import '../../visits/data/models/visit_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const Color _background = Color(0xFFF6F8FB);
  static const Color _heading = Color(0xFF101828);
  static const Color _body = Color(0xFF667085);
  static const Color _muted = Color(0xFF98A2B3);
  static const Color _border = Color(0xFFE4E7EC);

  static const Color _warning = Color(0xFFB54708);
  static const Color _warningBackground = Color(0xFFFFFAEB);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isRunningTest =
          !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

      if (isRunningTest) return;

      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    await Future.wait([
      ref.read(marketplaceProvider.notifier).load(refresh: true),

      ref.read(myShiftsProvider.notifier).load(refresh: true),

      ref.read(visitsProvider.notifier).load(refresh: true),

      ref.read(notificationsProvider.notifier).load(refresh: true),

      ref.read(billingProvider.notifier).loadWallet(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final marketplaceState = ref.watch(marketplaceProvider);

    final myShiftsState = ref.watch(myShiftsProvider);

    final visitsState = ref.watch(visitsProvider);

    final billingState = ref.watch(billingProvider);

    final unreadCount = ref.watch(unreadCountProvider);

    final user = authState.user;

    final assignments = myShiftsState.assignments;

    final visits = visitsState.visits;

    final wallet = billingState.wallet;

    final openShifts = marketplaceState.shifts.length;

    final nextAssignment = _findNextAssignment(assignments);

    final nextVisit = _findNextVisit(visits);

    final attentionVisits = _attentionVisits(visits);

    final firstName = user?.nurseProfile?.firstName.trim();
    final displayFirstName = firstName != null && firstName.isNotEmpty
        ? firstName
        : 'Nurse';

    return Scaffold(
      backgroundColor: _background,
      body: RefreshIndicator(
        color: accentColor,
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(firstName: displayFirstName, unreadCount: unreadCount),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNextUpCard(
                      nextAssignment: nextAssignment,
                      nextVisit: nextVisit,
                      assignments: assignments,
                    ),

                    const SizedBox(height: 26),

                    _sectionHeader(
                      title: 'Earnings',
                      subtitle: 'Your earnings and available balance.',
                    ),

                    const SizedBox(height: 14),

                    if (wallet != null)
                      WalletCard(wallet: wallet)
                    else
                      _buildWalletPlaceholder(
                        isLoading:
                            billingState.walletStatus == BillingStatus.loading,
                        hasError:
                            billingState.walletStatus == BillingStatus.error,
                      ),

                    const SizedBox(height: 28),

                    _sectionHeader(
                      title: 'Your activity',
                      subtitle: 'A quick overview of your TrabajoHub account.',
                    ),

                    const SizedBox(height: 14),

                    _buildAnalyticsGrid(
                      openShifts: openShifts,
                      assignments: assignments.length,
                      visits: visits.length,
                      alerts: unreadCount,
                    ),

                    const SizedBox(height: 24),

                    _buildActivityOverview(
                      openShifts: openShifts,
                      assignments: assignments.length,
                      visits: visits.length,
                      alerts: unreadCount,
                    ),

                    if (attentionVisits.isNotEmpty) ...[
                      const SizedBox(height: 24),

                      _buildAttentionCard(count: attentionVisits.length),
                    ],

                    const SizedBox(height: 28),

                    _sectionHeader(
                      title: 'Quick actions',
                      subtitle: 'Jump straight to what you need.',
                    ),

                    const SizedBox(height: 14),

                    _buildQuickActions(unreadCount: unreadCount),

                    const SizedBox(height: 30),

                    _sectionHeader(
                      title: 'Available shifts',
                      subtitle: 'Browse opportunities that match your profile.',
                      actionLabel: 'View all',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MarketplaceScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    const MiniMarketplaceSection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar({
    required String firstName,
    required int unreadCount,
  }) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 210,
      toolbarHeight: 72,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: accentColor,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _NotificationButton(
            unreadCount: unreadCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ),
      ],
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/app_icon.png', fit: BoxFit.contain),
            ),
          ),

          const SizedBox(width: 11),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TrabajoHub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'Nurse',
                style: TextStyle(
                  color: Color(0xDFFFFFFF),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 88, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_greeting()},',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .82),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.05,
                      letterSpacing: -.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    'Here’s what is happening with your schedule today.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .88),
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextUpCard({
    required ShiftAssignmentModel? nextAssignment,
    required VisitModel? nextVisit,
    required List<ShiftAssignmentModel> assignments,
  }) {
    late String title;
    late String subtitle;
    late String buttonLabel;
    late IconData icon;
    late VoidCallback action;

    if (nextAssignment != null) {
      title = 'Your next shift';

      subtitle = _formatRelative(nextAssignment.shift!.scheduledStart);

      buttonLabel = 'View shift';
      icon = Icons.calendar_today_rounded;

      action = () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 1)),
        );
      };
    } else if (nextVisit != null) {
      title = 'Your next visit';

      subtitle = _formatRelative(nextVisit.shiftInfo!.scheduledStart);

      final location = nextVisit.shiftInfo!.locationDisplay;

      if (location != '—') {
        subtitle = '$subtitle · $location';
      }

      buttonLabel = 'View visit';
      icon = Icons.route_rounded;

      action = () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 2)),
        );
      };
    } else if (assignments.isNotEmpty) {
      title = 'Active assignments';

      subtitle =
          '${assignments.length} active assignment'
          '${assignments.length == 1 ? '' : 's'} on your account';

      buttonLabel = 'View assignments';

      icon = Icons.assignment_turned_in_outlined;

      action = () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 1)),
        );
      };
    } else {
      title = 'Ready for your next shift?';

      subtitle =
          'Browse the marketplace and find an opportunity that works for you.';

      buttonLabel = 'Find shifts';

      icon = Icons.explore_outlined;

      action = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
        );
      };
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D101828),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 23),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'NEXT UP',
                  style: TextStyle(
                    color: _body,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Text(
            title,
            style: const TextStyle(
              color: _heading,
              fontSize: 20,
              letterSpacing: -.35,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            subtitle,
            style: const TextStyle(color: _body, fontSize: 13.5, height: 1.45),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: action,
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor.withValues(alpha: .22)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletPlaceholder({
    required bool isLoading,
    required bool hasError,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: accentColor,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError
                      ? 'Earnings unavailable'
                      : isLoading
                      ? 'Loading your earnings'
                      : 'Your earnings',
                  style: const TextStyle(
                    color: _heading,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  hasError
                      ? 'We could not load your wallet. Pull down to try again.'
                      : isLoading
                      ? 'Getting your latest wallet balance...'
                      : 'Pull down to refresh your wallet.',
                  style: const TextStyle(
                    color: _body,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: accentColor,
              ),
            )
          else if (hasError)
            IconButton(
              tooltip: 'Try again',
              onPressed: () {
                ref.read(billingProvider.notifier).loadWallet();
              },
              icon: Icon(Icons.refresh_rounded, color: accentColor),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid({
    required int openShifts,
    required int assignments,
    required int visits,
    required int alerts,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,

      // Prevents the previous
      // bottom-overflow issue.
      childAspectRatio: 1.20,

      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _AnalyticsCard(
          title: 'Open shifts',
          value: '$openShifts',
          subtitle: 'Available now',
          icon: Icons.work_outline_rounded,
          accent: accentColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
            );
          },
        ),

        _AnalyticsCard(
          title: 'Assignments',
          value: '$assignments',
          subtitle: 'My shifts',
          icon: Icons.assignment_turned_in_outlined,
          accent: const Color(0xFF475467),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ActiveSession(pageIndex: 1),
              ),
            );
          },
        ),

        _AnalyticsCard(
          title: 'Visits',
          value: '$visits',
          subtitle: 'Visit activity',
          icon: Icons.route_outlined,
          accent: const Color(0xFF175CD3),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ActiveSession(pageIndex: 2),
              ),
            );
          },
        ),

        _AnalyticsCard(
          title: 'Alerts',
          value: '$alerts',
          subtitle: alerts > 0 ? 'Needs review' : 'All caught up',
          icon: alerts > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_rounded,
          accent: alerts > 0 ? const Color(0xFFB54708) : accentColor,
          highlighted: alerts > 0,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityOverview({
    required int openShifts,
    required int assignments,
    required int visits,
    required int alerts,
  }) {
    final maximum = [
      openShifts,
      assignments,
      visits,
      alerts,
      1,
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity overview',
                      style: TextStyle(
                        color: _heading,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your current TrabajoHub activity',
                      style: TextStyle(color: _body, fontSize: 12),
                    ),
                  ],
                ),
              ),

              Icon(Icons.insights_rounded, color: _muted, size: 21),
            ],
          ),

          const SizedBox(height: 22),

          _ActivityBar(
            label: 'Open shifts',
            value: openShifts,
            progress: openShifts / maximum,
            accent: accentColor,
          ),

          const SizedBox(height: 16),

          _ActivityBar(
            label: 'Assignments',
            value: assignments,
            progress: assignments / maximum,
            accent: const Color(0xFF475467),
          ),

          const SizedBox(height: 16),

          _ActivityBar(
            label: 'Visits',
            value: visits,
            progress: visits / maximum,
            accent: const Color(0xFF175CD3),
          ),

          const SizedBox(height: 16),

          _ActivityBar(
            label: 'Alerts',
            value: alerts,
            progress: alerts / maximum,
            accent: const Color(0xFFB54708),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionCard({required int count}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ActiveSession(pageIndex: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _warningBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFEDFA8)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _warning.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: _warning,
                  size: 22,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Action needed',
                      style: TextStyle(
                        color: Color(0xFF7A2E0E),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count visit${count == 1 ? '' : 's'} '
                      '${count == 1 ? 'needs' : 'need'} your attention.',
                      style: const TextStyle(
                        color: _warning,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: _warning),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions({required int unreadCount}) {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickAction(
            icon: Icons.search_rounded,
            label: 'Find shifts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
              );
            },
          ),

          const SizedBox(width: 10),

          _QuickAction(
            icon: Icons.calendar_month_outlined,
            label: 'My shifts',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActiveSession(pageIndex: 1),
                ),
              );
            },
          ),

          const SizedBox(width: 10),

          _QuickAction(
            icon: Icons.route_outlined,
            label: 'My visits',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActiveSession(pageIndex: 2),
                ),
              );
            },
          ),

          const SizedBox(width: 10),

          _QuickAction(
            icon: unreadCount > 0
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_rounded,
            label: 'Alerts',
            badge: unreadCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
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
                  letterSpacing: -.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _body,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),

        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: accentColor),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  ShiftAssignmentModel? _findNextAssignment(
    List<ShiftAssignmentModel> assignments,
  ) {
    final now = DateTime.now();

    final upcoming =
        assignments.where((assignment) {
          final shift = assignment.shift;

          if (shift == null) {
            return false;
          }

          final assignmentStatus = assignment.status.trim().toUpperCase();

          final shiftStatus = shift.status.trim().toUpperCase();

          const excludedStatuses = {'CANCELLED', 'CANCELED', 'COMPLETED'};

          if (excludedStatuses.contains(assignmentStatus) ||
              excludedStatuses.contains(shiftStatus)) {
            return false;
          }

          return shift.scheduledStart.isAfter(now);
        }).toList()..sort(
          (a, b) => a.shift!.scheduledStart.compareTo(b.shift!.scheduledStart),
        );

    return upcoming.isEmpty ? null : upcoming.first;
  }

  VisitModel? _findNextVisit(List<VisitModel> visits) {
    final now = DateTime.now();

    final upcoming =
        visits.where((visit) {
          final shiftInfo = visit.shiftInfo;

          if (shiftInfo == null) {
            return false;
          }

          if (visit.status != VisitStatus.scheduled) {
            return false;
          }

          final shiftStatus = shiftInfo.status.trim().toUpperCase();

          const excludedShiftStatuses = {'CANCELLED', 'CANCELED', 'COMPLETED'};

          if (excludedShiftStatuses.contains(shiftStatus)) {
            return false;
          }

          return shiftInfo.scheduledStart.isAfter(now);
        }).toList()..sort(
          (a, b) => a.shiftInfo!.scheduledStart.compareTo(
            b.shiftInfo!.scheduledStart,
          ),
        );

    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<VisitModel> _attentionVisits(List<VisitModel> visits) {
    return visits
        .where(
          (visit) =>
              visit.overrideRequired || visit.status == VisitStatus.flagged,
        )
        .toList();
  }
}

class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationButton({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  unreadCount > 0
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          if (unreadCount > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF04438),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool highlighted;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFFFFAEB) : Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFFEDFA8)
                  : const Color(0xFFE4E7EC),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08101828),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 19),
                  ),

                  Icon(
                    Icons.arrow_outward_rounded,
                    color: accent.withValues(alpha: .55),
                    size: 16,
                  ),
                ],
              ),

              const SizedBox(height: 9),

              Text(
                value,
                style: TextStyle(
                  color: highlighted ? accent : const Color(0xFF101828),
                  fontSize: 24,
                  height: 1,
                  letterSpacing: -.5,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityBar extends StatelessWidget {
  final String label;
  final int value;
  final double progress;
  final Color accent;

  const _ActivityBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF475467),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Text(
              '$value',
              style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 7,
            backgroundColor: const Color(0xFFF2F4F7),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),

                    if (badge > 0)
                      Positioned(
                        top: -5,
                        right: -6,
                        child: Container(
                          width: 17,
                          height: 17,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF04438),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 9),

                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;

  if (hour < 12) {
    return 'Good morning';
  }

  if (hour < 17) {
    return 'Good afternoon';
  }

  return 'Good evening';
}

String _formatRelative(DateTime dt) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final target = DateTime(dt.year, dt.month, dt.day);

  final difference = target.difference(today).inDays;

  final hour = dt.hour == 0
      ? 12
      : dt.hour > 12
      ? dt.hour - 12
      : dt.hour;

  final minute = dt.minute.toString().padLeft(2, '0');

  final period = dt.hour >= 12 ? 'PM' : 'AM';

  final time = '$hour:$minute $period';

  if (difference == 0) {
    return 'Today, $time';
  }

  if (difference == 1) {
    return 'Tomorrow, $time';
  }

  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  if (difference > 1 && difference < 7) {
    return '${weekdays[dt.weekday - 1]}, $time';
  }

  return '${months[dt.month - 1]} ${dt.day}, $time';
}
