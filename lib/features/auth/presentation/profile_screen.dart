import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import 'package:trabajo_hub/features/auth/presentation/sign_in.dart';
import 'package:trabajo_hub/features/cases/presentation/cases_screen.dart';
import 'package:trabajo_hub/features/credentials/presentation/credentials_screen.dart';
import 'package:trabajo_hub/features/support/presentation/ticket_history_screen.dart';
import 'package:trabajo_hub/features/visits/presentation/visits_screen.dart';
import 'package:trabajo_hub/features/notifications/presentation/notification_preferences_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/cache/app_cache.dart';
import '../../../core/widgets/buttons/button_big.dart';
import '../../billing/presentation/wallet_screen.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../support/presentation/faq_screen.dart';
import '../../support/presentation/support_screen.dart';
import '../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import 'privacy_data_screen.dart';
import 'two_fa_setup_screen.dart';
import 'widget/avatar.dart';
import 'widget/payout_method_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const Color _background = Color(0xFFF6F8FB);
  static const Color _heading = Color(0xFF101828);
  static const Color _body = Color(0xFF667085);
  static const Color _muted = Color(0xFF98A2B3);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).fetchMe();
    });
  }

  Future<void> _refreshProfile() async {
    await ref.read(authProvider.notifier).fetchMe();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (authState.isLoading && user == null) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    if (user == null) {
      return Scaffold(backgroundColor: _background, body: _buildLoadError());
    }

    final nurseProfile = user.nurseProfile;

    final credentials = nurseProfile?.credentials ?? <CredentialSummary>[];

    final approvedCredentials = credentials
        .where((credential) => credential.status == 'APPROVED')
        .length;

    return Scaffold(
      backgroundColor: _background,
      body: RefreshIndicator(
        color: accentColor,
        onRefresh: _refreshProfile,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildProfileAppBar(user),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileCompletionCard(user: user),

                    if (user.isNurse && nurseProfile != null) ...[
                      const SizedBox(height: 16),

                      _ProfessionalOverviewCard(
                        user: user,
                        approvedCredentials: approvedCredentials,
                        credentialCount: credentials.length,
                      ),

                      const SizedBox(height: 26),

                      _sectionHeading(
                        title: 'Earnings & payouts',
                        subtitle:
                            'Track your earnings and control how TrabajoHub pays you.',
                      ),

                      const SizedBox(height: 13),

                      _WalletCard(wallet: nurseProfile.wallet),

                      const SizedBox(height: 13),

                      const PayoutMethodCard(),

                      const SizedBox(height: 26),

                      _sectionHeading(
                        title: 'Professional readiness',
                        subtitle:
                            'Keep your credentials current so you remain ready for opportunities.',
                      ),

                      const SizedBox(height: 13),

                      _CredentialsCard(credentials: credentials),

                      const SizedBox(height: 26),
                    ],

                    _sectionHeading(
                      title: 'Personal information',
                      subtitle:
                          'Review the details connected to your TrabajoHub account.',
                    ),

                    const SizedBox(height: 13),

                    _InfoCard(user: user),

                    const SizedBox(height: 26),

                    _sectionHeading(
                      title: 'Work & activity',
                      subtitle:
                          'Your schedule, visits, case records and work activity.',
                    ),

                    const SizedBox(height: 13),

                    const _ActivitiesCard(),

                    const SizedBox(height: 26),

                    _sectionHeading(
                      title: 'Security & preferences',
                      subtitle:
                          'Control notifications, password protection and account security.',
                    ),

                    const SizedBox(height: 13),

                    _ActionsCard(user: user),

                    const SizedBox(height: 26),

                    _sectionHeading(
                      title: 'Help & support',
                      subtitle:
                          'Find answers, contact us or review your support requests.',
                    ),

                    const SizedBox(height: 13),

                    const _SupportCard(),

                    const SizedBox(height: 28),

                    const _DeleteAccountCard(),

                    const SizedBox(height: 18),

                    _LogoutButton(
                      onLogout: () async {
                        await ref.read(authProvider.notifier).logout();

                        AppCache.instance.clear();

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SignIn()),
                          (_) => false,
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'TrabajoHub Nurse',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Secure healthcare workforce access',
                            style: TextStyle(
                              color: Color(0xFFB0B7C3),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildProfileAppBar(UserModel user) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 360,
      toolbarHeight: 70,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: accentColor,
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,

      title: Row(
        children: [
          Container(
            width: 37,
            height: 37,
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

          const SizedBox(width: 10),

          const Text(
            'My Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -.25,
            ),
          ),
        ],
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Center(
            child: Material(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => _openEditSheet(context, user),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],

      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _ProfileHeader(user: user),
      ),
    );
  }

  Widget _sectionHeading({required String title, required String subtitle}) {
    return Column(
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
          style: const TextStyle(color: _body, fontSize: 12.5, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_outlined,
                color: accentColor,
                size: 29,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load profile',
              style: TextStyle(
                color: _heading,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'We could not retrieve your account information. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _body, fontSize: 13, height: 1.45),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: _refreshProfile,
              icon: Icon(Icons.refresh_rounded, color: accentColor),
              label: Text(
                'Try again',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditSheet(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(child: _EditProfileSheet(user: user)),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final nurseProfile = user.nurseProfile;

    return Container(
      decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .25),
                  ),
                ),
                child: Avatar(user: user),
              ),

              const SizedBox(height: 13),

              Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: -.5,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusPill(user.verificationStatus),

                  if (user.isNurse && nurseProfile != null)
                    _DesignationPill(nurseProfile.designation),

                  if (user.twoFactorEnabled) const _HeaderSecurityPill(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  final UserModel user;

  const _ProfileCompletionCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final np = user.nurseProfile;

    final checks = <bool>[
      user.email.trim().isNotEmpty,

      user.phone != null && user.phone!.trim().isNotEmpty,

      (np?.firstName ?? '').trim().isNotEmpty,

      (np?.lastName ?? '').trim().isNotEmpty,

      (np?.bio ?? '').trim().isNotEmpty,

      (np?.city ?? '').trim().isNotEmpty,

      (np?.state ?? '').trim().isNotEmpty,

      np?.credentials.isNotEmpty ?? false,
    ];

    final completed = checks.where((item) => item).length;

    final progress = checks.isEmpty ? 0.0 : completed / checks.length;

    final percent = (progress * 100).round();

    final complete = percent == 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09101828),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: complete
                      ? const Color(0xFFECFDF3)
                      : accentColor.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  complete
                      ? Icons.verified_rounded
                      : Icons.person_outline_rounded,
                  color: complete ? const Color(0xFF027A48) : accentColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? 'Profile ready' : 'Complete your profile',
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      complete
                          ? 'Your professional profile contains the key information TrabajoHub needs.'
                          : 'A complete profile helps facilities understand your professional background.',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Text(
                '$percent%',
                style: TextStyle(
                  color: complete ? const Color(0xFF027A48) : accentColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFF2F4F7),
              valueColor: AlwaysStoppedAnimation<Color>(
                complete ? const Color(0xFF12B76A) : accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalOverviewCard extends StatelessWidget {
  final UserModel user;
  final int approvedCredentials;
  final int credentialCount;

  const _ProfessionalOverviewCard({
    required this.user,
    required this.approvedCredentials,
    required this.credentialCount,
  });

  @override
  Widget build(BuildContext context) {
    final nurseProfile = user.nurseProfile!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08101828),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ProfileMetric(
                  icon: Icons.verified_outlined,
                  value: _friendlyVerificationStatus(user.verificationStatus),
                  label: 'Account',
                  accent: _verificationColor(user.verificationStatus),
                ),
              ),

              Container(width: 1, height: 56, color: const Color(0xFFE4E7EC)),

              Expanded(
                child: _ProfileMetric(
                  icon: Icons.workspace_premium_outlined,
                  value: nurseProfile.designation,
                  label: 'Designation',
                  accent: accentColor,
                ),
              ),

              Container(width: 1, height: 56, color: const Color(0xFFE4E7EC)),

              Expanded(
                child: _ProfileMetric(
                  icon: Icons.badge_outlined,
                  value: '$approvedCredentials/$credentialCount',
                  label: 'Approved',
                  accent: const Color(0xFF175CD3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: nurseProfile.isAvailable
                  ? const Color(0xFFECFDF3)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  nurseProfile.isAvailable
                      ? Icons.check_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  color: nurseProfile.isAvailable
                      ? const Color(0xFF027A48)
                      : const Color(0xFF667085),
                  size: 19,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    nurseProfile.isAvailable
                        ? 'You are currently available for new opportunities'
                        : 'You are currently marked unavailable',
                    style: TextStyle(
                      color: nurseProfile.isAvailable
                          ? const Color(0xFF027A48)
                          : const Color(0xFF475467),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ProfileMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _ProfileMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF98A2B3), fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _verificationColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'VERIFIED'
                ? Icons.verified_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 13,
          ),

          const SizedBox(width: 4),

          Text(
            _friendlyVerificationStatus(status),
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignationPill extends StatelessWidget {
  final String designation;

  const _DesignationPill(this.designation);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Text(
        designation,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderSecurityPill extends StatelessWidget {
  const _HeaderSecurityPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text(
            '2FA ON',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatefulWidget {
  final WalletSummary? wallet;

  const _WalletCard({this.wallet});

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  bool _showMoney = true;

  String _money(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  String _value(double value) {
    return _showMoney ? _money(value) : '••••••';
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: ColorConstants.appGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: .20),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY EARNINGS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'TrabajoHub Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: _showMoney ? 'Hide earnings' : 'Show earnings',
                      onPressed: () {
                        setState(() {
                          _showMoney = !_showMoney;
                        });
                      },
                      icon: Icon(
                        _showMoney
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Lifetime earnings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _value(wallet?.lifetimeEarnings ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: .14),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _WalletStat(
                        label: 'Available',
                        value: _value(wallet?.availableBalance ?? 0),
                        icon: Icons.account_balance_outlined,
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 44,
                      color: Colors.white.withValues(alpha: .16),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: _WalletStat(
                        label: 'Pending',
                        value: _value(wallet?.pendingBalance ?? 0),
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.only(top: 13),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: .12),
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'View earnings & payout history',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
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
}

class _WalletStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _WalletStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white70, size: 17),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 10.5),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CredentialsCard extends StatefulWidget {
  final List<CredentialSummary> credentials;

  const _CredentialsCard({required this.credentials});

  @override
  State<_CredentialsCard> createState() => _CredentialsCardState();
}

class _CredentialsCardState extends State<_CredentialsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final approved = widget.credentials
        .where((credential) => credential.status == 'APPROVED')
        .length;

    final needsAttention = widget.credentials
        .where(
          (credential) =>
              credential.status == 'REJECTED' ||
              credential.status == 'EXPIRED' ||
              credential.isExpiringSoon,
        )
        .length;

    return _SectionCard(
      title: 'Credentials',
      icon: Icons.workspace_premium_outlined,

      trailing: _CountBadge(
        label: '$approved/${widget.credentials.length} approved',
        attention: needsAttention > 0,
      ),

      child: Column(
        children: [
          if (widget.credentials.isEmpty)
            _EmptyState(
              icon: Icons.badge_outlined,
              title: 'No credentials uploaded',
              subtitle:
                  'Add your professional credentials so facilities can verify your eligibility.',
              actionLabel: 'Upload credentials',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CredentialsScreen()),
                );
              },
            )
          else ...[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        needsAttention > 0
                            ? '$needsAttention credential item${needsAttention == 1 ? '' : 's'} may need attention.'
                            : 'Your credential summary is ready to review.',
                        style: TextStyle(
                          color: needsAttention > 0
                              ? const Color(0xFFB54708)
                              : const Color(0xFF667085),
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: needsAttention > 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF98A2B3),
                    ),
                  ],
                ),
              ),
            ),

            if (_expanded) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFEAECF0)),
              const SizedBox(height: 6),
              ...widget.credentials.map(
                (credential) => _CredentialRow(credential: credential),
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CredentialsScreen()),
                  );
                },
                icon: Icon(
                  Icons.manage_accounts_outlined,
                  color: accentColor,
                  size: 18,
                ),
                label: Text(
                  'Manage credentials',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: accentColor.withValues(alpha: .22)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final CredentialSummary credential;

  const _CredentialRow({required this.credential});

  static const _statusColors = {
    'APPROVED': (Color(0xFFE1F5EE), Color(0xFF0F6E56)),
    'PENDING': (Color(0xFFFAEEDA), Color(0xFF854F0B)),
    'REJECTED': (Color(0xFFFCEBEB), Color(0xFFA32D2D)),
    'EXPIRED': (Color(0xFFF1EFE8), Color(0xFF5F5E5A)),
  };

  @override
  Widget build(BuildContext context) {
    final colors =
        _statusColors[credential.status] ?? _statusColors['PENDING']!;

    final expiryLabel = credential.expiresAt != null
        ? DateFormat('MMM d, yyyy').format(credential.expiresAt!)
        : 'No expiry';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.$1,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              credential.status == 'APPROVED'
                  ? Icons.verified_outlined
                  : Icons.badge_outlined,
              color: colors.$2,
              size: 19,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credential.type.replaceAll('_', ' '),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF344054),
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Color(0xFF98A2B3),
                    ),

                    const SizedBox(width: 4),

                    Flexible(
                      child: Text(
                        expiryLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                    ),

                    if (credential.isExpiringSoon) ...[
                      const SizedBox(width: 6),

                      const Flexible(
                        child: Text(
                          'Expiring soon',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFB54708),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.$1,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              credential.status,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: colors.$2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatefulWidget {
  final UserModel user;

  const _InfoCard({required this.user});

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final np = widget.user.nurseProfile;

    return _SectionCard(
      title: 'Account information',
      icon: Icons.person_outline_rounded,

      trailing: IconButton(
        tooltip: _expanded ? 'Collapse' : 'Expand',
        onPressed: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        icon: Icon(
          _expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          color: const Color(0xFF98A2B3),
        ),
      ),

      child: AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),

        secondChild: Column(
          children: [
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: widget.user.email,
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: (widget.user.phone ?? '').trim().isNotEmpty
                  ? widget.user.phone!.trim()
                  : 'Not added',
            ),

            if (np != null) ...[
              if (np.city != null && np.state != null)
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: '${np.city}, ${np.state}',
                ),

              if (np.yearsOfExperience != null)
                _InfoRow(
                  icon: Icons.work_outline_rounded,
                  label: 'Experience',
                  value: '${np.yearsOfExperience} yrs',
                ),

              if (np.availabilityRadius != null)
                _InfoRow(
                  icon: Icons.radar_rounded,
                  label: 'Travel radius',
                  value: '${np.availabilityRadius?.toStringAsFixed(0)} miles',
                ),

              _InfoRow(
                icon: np.isAvailable
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                label: 'Availability',
                value: np.isAvailable ? 'Available' : 'Unavailable',
                valueColor: np.isAvailable
                    ? const Color(0xFF027A48)
                    : const Color(0xFFB54708),
              ),

              if ((np.bio ?? '').trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.notes_rounded,
                  label: 'Bio',
                  value: np.bio!,
                  multiLine: true,
                ),
            ],

            if (widget.user.lastLoginAt != null)
              _InfoRow(
                icon: Icons.access_time_outlined,
                label: 'Last login',
                value: DateFormat(
                  'MMM d, yyyy – h:mm a',
                ).format(widget.user.lastLoginAt!),
              ),
          ],
        ),

        crossFadeState: _expanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,

        duration: const Duration(milliseconds: 180),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool multiLine;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: multiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF667085)),
          ),

          const SizedBox(width: 11),

          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF98A2B3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Text(
              value,
              maxLines: multiLine ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF344054),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitiesCard extends StatelessWidget {
  const _ActivitiesCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Work center',
      icon: Icons.work_outline_rounded,
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.calendar_month_rounded,
            label: 'My calendar',
            subtitle: 'View your schedule in one place',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CalendarScreen()),
              );
            },
          ),

          const _ActionDivider(),

          _ActionRow(
            icon: Icons.route_outlined,
            label: 'My visits',
            subtitle: 'Review scheduled and completed visits',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VisitsScreen()),
              );
            },
          ),

          const _ActionDivider(),

          _ActionRow(
            icon: Icons.folder_copy_outlined,
            label: 'Case archive & logs',
            subtitle: 'Review case records and historical logs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CasesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final UserModel user;

  const _ActionsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Security & preferences',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.notifications_outlined,
            label: 'Notification preferences',
            subtitle: 'Control delivery channels and the alerts you receive',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),

          const _ActionDivider(),

          _ActionRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy & data',
            subtitle: 'Export your account data and review privacy controls',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyDataScreen()),
              );
            },
          ),

          const _ActionDivider(),

          _ActionRow(
            icon: Icons.lock_outline_rounded,
            label: 'Change password',
            subtitle: 'Update the password used to sign in',
            onTap: () => _openChangePassword(context),
          ),

          const _ActionDivider(),

          _ActionRow(
            icon: user.twoFactorEnabled
                ? Icons.shield_rounded
                : Icons.shield_outlined,

            label: user.twoFactorEnabled
                ? 'Two-factor authentication'
                : 'Enable two-factor authentication',

            subtitle: user.twoFactorEnabled
                ? 'Extra sign-in protection is enabled'
                : 'Add another layer of account protection',

            labelColor: user.twoFactorEnabled ? const Color(0xFF027A48) : null,

            trailing: user.twoFactorEnabled ? const _SecurityOnBadge() : null,

            onTap: () => user.twoFactorEnabled
                ? _openDisable2FA(context)
                : _openSetup2FA(context),
          ),
        ],
      ),
    );
  }

  void _openChangePassword(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(child: _ChangePasswordSheet()),
      ),
    );
  }

  void _openSetup2FA(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TwoFASetupScreen()),
    );
  }

  Future<void> _openDisable2FA(BuildContext context) async {
    final ok = await Disable2FASheet.show(context);

    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-factor authentication disabled'),
          backgroundColor: Color(0xFF536C79),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SecurityOnBadge extends StatelessWidget {
  const _SecurityOnBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'ON',
        style: TextStyle(
          color: Color(0xFF027A48),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Support',
      icon: Icons.support_agent_rounded,
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.support_agent_rounded,
            label: 'Contact support',
            subtitle: 'Get help directly from the TrabajoHub team',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SupportScreen()),
              );
            },
          ),

          const _ActionDivider(),

          _ActionRow(
            icon: Icons.confirmation_number_outlined,
            label: 'My support requests',
            subtitle: 'Review your previous and active tickets',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TicketHistoryScreen()),
              );
            },
          ),

          const _ActionDivider(),

          _ActionRow(
            icon: Icons.help_outline_rounded,
            label: 'Frequently asked questions',
            subtitle: 'Find quick answers to common questions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FaqScreen()),
              );
            },
          ),

          const _ActionDivider(),

          _ActionRow(
            icon: Icons.language_rounded,
            label: 'TrabajoHub support center',
            subtitle: 'Open the support website',
            onTap: () async {
              final uri = Uri.parse('https://trabajohub.com/support');

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountCard extends ConsumerWidget {
  const _DeleteAccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFECDCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB42318),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Account control',
                style: TextStyle(
                  color: Color(0xFF912018),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Deleting your account is permanent and removes your TrabajoHub account data. Only continue if you are certain.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7A271A),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showDeleteAccountDialog(context);
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete account'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFDA29B)),
                foregroundColor: const Color(0xFFB42318),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: _DeleteAccountSheet(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08101828),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: accentColor),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? labelColor;
  final Widget? trailing;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.labelColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = labelColor ?? const Color(0xFF344054);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (labelColor ?? accentColor).withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: labelColor ?? accentColor),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 3),

                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (trailing != null) ...[trailing!, const SizedBox(width: 7)],

              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 52, color: Color(0xFFEAECF0));
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final bool attention;

  const _CountBadge({required this.label, this.attention = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: attention ? const Color(0xFFFFFAEB) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: attention ? const Color(0xFFB54708) : const Color(0xFF667085),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F4F7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF667085), size: 22),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF98A2B3),
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 13),

          TextButton(
            onPressed: onPressed,
            child: Text(
              actionLabel,
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onLogout,

        icon: const Icon(Icons.logout_rounded, size: 19),

        label: const Text('Log out of TrabajoHub'),

        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB42318),
          backgroundColor: const Color(0xFFFFFBFA),
          side: const BorderSide(color: Color(0xFFFDA29B)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _passwordController = TextEditingController();

  final _reasonController = TextEditingController();

  String? _error;

  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    setState(() {
      _error = null;
    });

    final password = _passwordController.text.trim();

    final reason = _reasonController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _error = 'Please enter your password to confirm.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await ref
        .read(authProvider.notifier)
        .deleteAccount(
          password: password,
          reason: reason.isEmpty ? null : reason,
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignIn()),
        (_) => false,
      );

      return;
    }

    setState(() {
      _error = ref.read(authProvider).error ?? 'Unable to delete account.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 22, 20, bottom + 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFB42318),
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101828),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'This action cannot be undone.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Text(
              'Enter your current password to confirm permanent account deletion.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Color(0xFF475467),
              ),
            ),

            const SizedBox(height: 16),

            _SheetField(
              controller: _passwordController,
              label: 'Current password',
              obscureText: !_showPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
            ),

            const SizedBox(height: 13),

            _SheetField(
              controller: _reasonController,
              label: 'Reason for leaving (optional)',
              maxLines: 3,
            ),

            if (_error != null) ...[
              const SizedBox(height: 13),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3F2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB42318),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Delete account',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserModel user;

  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zipCode;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();

    final nurseProfile = widget.user.nurseProfile;

    _firstName = TextEditingController(text: nurseProfile?.firstName ?? '');

    _lastName = TextEditingController(text: nurseProfile?.lastName ?? '');

    _email = TextEditingController(text: widget.user.email);

    _phone = TextEditingController(text: widget.user.phone ?? '');

    _addressLine1 = TextEditingController(
      text: nurseProfile?.addressLine1 ?? '',
    );

    _addressLine2 = TextEditingController(
      text: nurseProfile?.addressLine2 ?? '',
    );

    _city = TextEditingController(text: nurseProfile?.city ?? '');

    _state = TextEditingController(text: nurseProfile?.state ?? '');

    _zipCode = TextEditingController(text: nurseProfile?.zipCode ?? '');

    _bio = TextEditingController(text: nurseProfile?.bio ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _state.dispose();
    _zipCode.dispose();
    _bio.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    final phone = _phone.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('First name and last name are required.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final success = await ref.read(authProvider.notifier).updateProfile({
      'firstName': firstName,
      'lastName': lastName,

      if (phone.isNotEmpty) 'phone': phone,

      'bio': _bio.text.trim(),

      'addressLine1': _addressLine1.text.trim(),
      'addressLine2': _addressLine2.text.trim(),
      'city': _city.text.trim(),
      'state': _state.text.trim(),
      'zipCode': _zipCode.text.trim(),
    });

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authProvider).error ?? 'Unable to update profile.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Color(0xFF027A48),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .86,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 22, 22, bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.manage_accounts_outlined,
                    color: accentColor,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 13),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit profile',
                        style: TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.35,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Keep your personal and professional information current.',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            const _EditSectionTitle(
              title: 'Personal information',
              subtitle: 'Your basic identity and contact information.',
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _SheetField(
                    controller: _firstName,
                    label: 'First name',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _SheetField(controller: _lastName, label: 'Last name'),
                ),
              ],
            ),

            const SizedBox(height: 13),

            _SheetField(
              controller: _phone,
              label: 'Phone number',
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),

            const _EditSectionTitle(
              title: 'Account email',
              subtitle: 'Your email is also used to sign in to TrabajoHub.',
            ),

            const SizedBox(height: 14),

            IgnorePointer(
              child: _SheetField(
                controller: _email,
                label: 'Email address',
                keyboardType: TextInputType.emailAddress,
              ),
            ),

            const SizedBox(height: 9),

            Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 15, color: accentColor),

                const SizedBox(width: 7),

                const Expanded(
                  child: Text(
                    'Email changes require verification for account security.',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () async {
                    final changed = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          _ChangeEmailDialog(currentEmail: widget.user.email),
                    );

                    if (!mounted || changed != true) {
                      return;
                    }

                    final refreshedEmail = ref.read(authProvider).user?.email;

                    if (refreshedEmail != null) {
                      _email.text = refreshedEmail;
                    }
                  },
                  child: Text(
                    'Change email',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const _EditSectionTitle(
              title: 'Home location',
              subtitle: 'Used for matching you with nearby work opportunities.',
            ),

            const SizedBox(height: 14),

            _SheetField(controller: _addressLine1, label: 'Address line 1'),

            const SizedBox(height: 13),

            _SheetField(
              controller: _addressLine2,
              label: 'Address line 2 (optional)',
            ),

            const SizedBox(height: 13),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _SheetField(controller: _city, label: 'City'),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _SheetField(controller: _state, label: 'State'),
                ),
              ],
            ),

            const SizedBox(height: 13),

            _SheetField(
              controller: _zipCode,
              label: 'ZIP code',
              keyboardType: TextInputType.streetAddress,
            ),

            const SizedBox(height: 24),

            const _EditSectionTitle(
              title: 'Professional profile',
              subtitle: 'Tell facilities a little about your experience.',
            ),

            const SizedBox(height: 14),

            _SheetField(
              controller: _bio,
              label: 'Professional bio',
              maxLines: 5,
            ),

            const SizedBox(height: 26),

            Button(
              buttonText: 'Save changes',
              onPressed: isLoading ? null : _save,
              isLoading: isLoading,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EditSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EditSectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF98A2B3),
            fontSize: 10.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ChangeEmailDialog extends ConsumerStatefulWidget {
  final String currentEmail;

  const _ChangeEmailDialog({required this.currentEmail});

  @override
  ConsumerState<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends ConsumerState<_ChangeEmailDialog> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _codeSent = false;
  String? _pendingEmail;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String? _validateEmail(String raw) {
    final email = raw.trim().toLowerCase();

    if (email.isEmpty) {
      return 'Enter your new email address.';
    }

    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

    if (!valid) {
      return 'Enter a valid email address.';
    }

    if (email == widget.currentEmail.trim().toLowerCase()) {
      return 'This is already your current email address.';
    }

    return null;
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim().toLowerCase();
    final validationError = _validateEmail(email);

    if (validationError != null) {
      setState(() {
        _localError = validationError;
      });
      return;
    }

    setState(() {
      _localError = null;
    });

    final result = await ref
        .read(authProvider.notifier)
        .sendEmailChangeCode(email);

    if (!mounted) {
      return;
    }

    if (result == null) {
      setState(() {
        _localError =
            ref.read(authProvider).error ?? 'Unable to send verification code.';
      });
      return;
    }

    setState(() {
      _pendingEmail = email;
      _codeSent = true;
      _codeController.clear();
      _localError = null;
    });
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();

    final email = _pendingEmail;

    if (email == null) {
      return;
    }

    final code = _codeController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _localError = 'Enter the 6-digit verification code.';
      });
      return;
    }

    setState(() {
      _localError = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .verifyEmailChange(email: email, code: code);

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        _localError =
            ref.read(authProvider).error ?? 'Unable to verify the new email.';
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _resendCode() async {
    final email = _pendingEmail;

    if (email == null) {
      return;
    }

    setState(() {
      _localError = null;
    });

    final result = await ref
        .read(authProvider.notifier)
        .sendEmailChangeCode(email);

    if (!mounted) {
      return;
    }

    if (result == null) {
      setState(() {
        _localError =
            ref.read(authProvider).error ??
            'Unable to resend verification code.';
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A new verification code was sent.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _codeSent
                        ? Icons.mark_email_read_outlined
                        : Icons.alternate_email_rounded,
                    color: accentColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _codeSent ? 'Verify new email' : 'Change email',
                        style: const TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _codeSent
                            ? 'Enter the code sent to $_pendingEmail.'
                            : 'We will verify your new email before changing your login address.',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            if (!_codeSent) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current email',
                      style: TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.currentEmail,
                      style: const TextStyle(
                        color: Color(0xFF344054),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SheetField(
                controller: _emailController,
                label: 'New email address',
                keyboardType: TextInputType.emailAddress,
              ),
            ] else ...[
              _SheetField(
                controller: _codeController,
                label: '6-digit verification code',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : _resendCode,
                  child: Text(
                    'Resend code',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],

            if (_localError != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDA29B)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFB42318),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _localError!,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 11.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : (_codeSent ? _verifyCode : _sendCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: accentColor.withValues(alpha: .45),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _codeSent
                            ? 'Verify & change email'
                            : 'Send verification code',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),

            if (_codeSent) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            _codeSent = false;
                            _pendingEmail = null;
                            _codeController.clear();
                            _localError = null;
                          });
                        },
                  child: const Text('Use a different email'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentPw = TextEditingController();

  final _newPw = TextEditingController();

  final _confirmPw = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newPw.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 8 characters'),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    if (_newPw.text != _confirmPw.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .changePassword(
          currentPassword: _currentPw.text,
          newPassword: _newPw.text,
        );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Password changed'
              : ref.read(authProvider).error ?? 'Failed',
        ),
        backgroundColor: success ? const Color(0xFF027A48) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 22, 20, bottom + 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded, color: accentColor),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Use a strong password you do not reuse elsewhere.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _SheetField(
            controller: _currentPw,
            label: 'Current password',
            obscureText: _obscureCurrent,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCurrent
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureCurrent = !_obscureCurrent;
                });
              },
            ),
          ),

          const SizedBox(height: 13),

          _SheetField(
            controller: _newPw,
            label: 'New password',
            obscureText: _obscureNew,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureNew = !_obscureNew;
                });
              },
            ),
          ),

          const SizedBox(height: 13),

          _SheetField(
            controller: _confirmPw,
            label: 'Confirm new password',
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          Button(
            buttonText: 'Update password',
            onPressed: isLoading ? null : _submit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;

  final String label;

  final bool obscureText;

  final TextInputType keyboardType;

  final int maxLines;

  final Widget? suffixIcon;

  const _SheetField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF344054),
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Color(0xFF101828)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

Color _verificationColor(String status) {
  switch (status) {
    case 'VERIFIED':
      return const Color(0xFF027A48);

    case 'PENDING':
      return const Color(0xFFB54708);

    case 'REJECTED':
      return const Color(0xFFB42318);

    default:
      return const Color(0xFF667085);
  }
}

String _friendlyVerificationStatus(String status) {
  switch (status) {
    case 'VERIFIED':
      return 'Verified';

    case 'PENDING':
      return 'Pending';

    case 'REJECTED':
      return 'Needs review';

    case 'UNVERIFIED':
      return 'Unverified';

    default:
      return status;
  }
}
