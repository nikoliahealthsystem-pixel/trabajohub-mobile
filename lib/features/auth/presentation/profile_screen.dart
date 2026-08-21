import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import 'package:trabajo_hub/features/auth/presentation/sign_in.dart';
import 'package:trabajo_hub/features/cases/presentation/cases_screen.dart';
import 'package:trabajo_hub/features/credentials/presentation/credentials_screen.dart';
import 'package:trabajo_hub/features/support/presentation/ticket_history_screen.dart';
import 'package:trabajo_hub/features/visits/presentation/visits_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/cache/app_cache.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/buttons/button_big.dart';
import '../../billing/presentation/wallet_screen.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../support/presentation/faq_screen.dart' hide accentColor;
import '../../support/presentation/support_screen.dart';
import '../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import 'two_fa_setup_screen.dart';
import 'widget/avatar.dart';
import 'widget/payout_method_card.dart';
import 'widget/push_notification_switch.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).fetchMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      body: authState.isLoading && user == null
          ?  Center(child: CircularProgressIndicator(color: accentColor))
          : user == null
          ? const Center(child: Text('Unable to load profile'))
          : NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              stretch: true,
              elevation: 0,
              backgroundColor: accentColor,

              systemOverlayStyle: SystemUiOverlayStyle.light,

              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,

                title: AnimatedOpacity(
                  opacity: innerBoxIsScrolled ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    user.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),

                background: _ProfileHeader(user: user),
              ),

              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => _openEditSheet(context, user),
                ),
              ],
            ),
          ];
        },

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (user.isNurse &&
                  user.nurseProfile != null) ...[
                _WalletCard(
                  wallet: user.nurseProfile!.wallet,
                ),
                const SizedBox(height: 12),
                _CredentialsCard(
                  credentials:
                  user.nurseProfile!.credentials,
                ),
                const SizedBox(height: 12),
              ],

              _InfoCard(user: user),
              const SizedBox(height: 12),

              _ActivitiesCard(user: user),
              const SizedBox(height: 12),
              _ActionsCard(user: user),

              const SizedBox(height: 12),
              _SupportCard(),
              const SizedBox(height: 12),

              _DeleteAccountCard(user: user),
              const SizedBox(height: 24),
              _LogoutButton(
                onLogout: () async {
                  await ref.read(authProvider.notifier).logout();
                  AppCache.instance.clear();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (BuildContext context) => SignIn()),
                    (_) => false,
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditSheet(BuildContext context, UserModel user) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) =>  Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 24),
          child: _EditProfileSheet(user: user))
    );
  }
}

// ─── Stripe Connect Card ─────────────────────────────────────

class _StripeConnectCard extends ConsumerWidget {
  final UserModel user;
  const _StripeConnectCard({required this.user, super.key});

  Future<void> _connectStripe(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authProvider.notifier).connectStripe();

    // Log for confirmation
    debugPrint("Stripe Onboarding Result: $result");

    if (result == null || result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['message'] ?? 'Failed to connect to Stripe'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // FIXED: Access the 'url' inside the 'data' map
    final data = result['data'];
    final String? urlString = data != null ? data['url'] : null;

    if (urlString != null) {
      final Uri url = Uri.parse(urlString);

      // Use externalApplication to ensure it opens in the phone's Chrome/Safari browser
      final launched = await launchUrl(
        url,
        mode: LaunchMode.inAppBrowserView,
      );

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Stripe. Please try again.')),
        );
      }
    } else {
      debugPrint("URL was null in the response data");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasStripe = user.nurseProfile?.stripeAccountId != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              Icon(Icons.account_balance_outlined, color: accentColor),
              SizedBox(width: 8),
              Text(
                'Payout Account',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.center,child: Text(
            hasStripe
                ? 'Stripe account is connected and ready for payouts'
                : 'Connect your bank account to receive payments from shifts',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: hasStripe ? const Color(0xFF0F6E56) : Colors.grey[600],
              fontSize: 13,
            ),
          ),),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _connectStripe(context, ref),
              icon: Icon(hasStripe ? Icons.settings_suggest : Icons.link,color: accentColor,),
              label: Text(hasStripe ? 'Manage Stripe Account' : 'Connect with Stripe',style: TextStyle(color: accentColor),),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:  BoxDecoration(
        gradient: ColorConstants.appGradient,
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Avatar(user: user),

            const SizedBox(height: 12),

            Text(
              user.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                _StatusPill(
                  user.verificationStatus,
                ),

                if (user.isNurse &&
                    user.nurseProfile != null) ...[
                  const SizedBox(width: 8),

                  _DesignationPill(
                    user.nurseProfile!
                        .designation,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Pills ───────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  static const _colors = {
    'VERIFIED': (Color(0xFFE1F5EE), Color(0xFF0F6E56)),
    'PENDING': (Color(0xFFFAEEDA), Color(0xFF854F0B)),
    'UNVERIFIED': (Color(0xFFF1EFE8), Color(0xFF5F5E5A)),
    'REJECTED': (Color(0xFFFCEBEB), Color(0xFFA32D2D)),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _colors[status] ?? _colors['UNVERIFIED']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.$2),
      ),
    );
  }
}

class _DesignationPill extends StatelessWidget {
  final String designation;
  const _DesignationPill(this.designation);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      designation,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

// ─── Wallet Card ─────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final WalletSummary? wallet;
  const _WalletCard({this.wallet});

  @override
  Widget build(BuildContext context) {
    final w = wallet;
    return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WalletScreen()),
        ),
       child:  Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:  ColorConstants.appGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text(
                'WALLET',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6),
              ),
              Spacer(),
              Text(
                'Click to view details',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _WalletStat(label: 'Available', value: w?.availableBalance ?? 0)),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(child: _WalletStat(label: 'Pending', value: w?.pendingBalance ?? 0)),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(child: _WalletStat(label: 'Lifetime', value: w?.lifetimeEarnings ?? 0)),
            ],
          ),
        ],
      ),
    ));
  }
}

class _WalletStat extends StatelessWidget {
  final String label;
  final double value;
  const _WalletStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '\$${value.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
  );
}

// ─── Credentials Card ────────────────────────────────────

class _CredentialsCard extends StatefulWidget {
  final List<CredentialSummary> credentials;
  const _CredentialsCard({required this.credentials});

  @override
  State<_CredentialsCard> createState() => _CredentialsCardState();
}

class _CredentialsCardState extends State<_CredentialsCard> {
  bool clicked = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: (){
          setState(() {
            clicked = !clicked;
          });
        },
        child:  _SectionCard(
      title: 'Credentials',
      trailing: Row(
        children: [
          Text(
            '${widget.credentials.where((c) => c.status == 'APPROVED').length}/${widget.credentials.length} approved',
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B4)),
          ),
          Icon( clicked ? Icons.arrow_drop_down:Icons.arrow_right,color: Colors.grey,)
        ],
      ),
      child: Column(
        children: [
          widget.credentials.isEmpty
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No credentials uploaded yet.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B4)),
            ),
          )
              : clicked? SizedBox.shrink() :  Column(
            children: widget.credentials.map((c) => _CredentialRow(credential: c)).toList(),
          ),
          TextButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CredentialsScreen())), child: Text('Manage Credentials',style: TextStyle(color: accentColor),))        ],
      ),
    ));
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
    final colors = _statusColors[credential.status] ?? _statusColors['PENDING']!;
    final expiryLabel = credential.expiresAt != null
        ? DateFormat('MMM d, yyyy').format(credential.expiresAt!)
        : 'No expiry';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credential.type.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2632)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF94A3B4)),
                    const SizedBox(width: 4),
                    Text(expiryLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B4))),
                    if (credential.isExpiringSoon)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text('Expiring soon', style: TextStyle(fontSize: 10, color: Color(0xFFB36000))),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(6)),
            child: Text(
              credential.status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.$2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Card ───────────────────────────────────────────

class _InfoCard extends StatefulWidget {
  final UserModel user;
  _InfoCard({required this.user,});

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {

  bool clicked = true;

  @override
  Widget build(BuildContext context) {
    final np = widget.user.nurseProfile;
    return GestureDetector(
      onTap: (){
        setState(() {
          clicked = !clicked;
        });
      },
    child:  _SectionCard(
      title: 'Account info',
      trailing: Icon( clicked ? Icons.arrow_drop_down:Icons.arrow_right,color: Colors.grey,),
      child: clicked? SizedBox.shrink() : Column(
        children: [
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: widget.user.email),
          if (widget.user.phone != null)
            _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: widget.user.phone!),
          if (np != null) ...[
            if (np.city != null && np.state != null)
              _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: '${np.city}, ${np.state}'),
            if (np.yearsOfExperience != null)
              _InfoRow(icon: Icons.work_outline, label: 'Experience', value: '${np.yearsOfExperience} yrs'),
            if (np.availabilityRadius != null)
              _InfoRow(icon: Icons.radar, label: 'Radius', value: '${np.availabilityRadius?.toStringAsFixed(0)} miles'),
            _InfoRow(
              icon: np.isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
              label: 'Available',
              value: np.isAvailable ? 'Yes' : 'No',
              valueColor: np.isAvailable ? const Color(0xFF0F6E56) : const Color(0xFFA32D2D),
            ),
          ],
          if (widget.user.lastLoginAt != null)
            _InfoRow(
              icon: Icons.access_time_outlined,
              label: 'Last login',
              value: DateFormat('MMM d, yyyy – h:mm a').format(widget.user.lastLoginAt!),
            ),
        ],
      ),
    ),);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B4)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B4))),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A2632),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Actions Card ────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  final UserModel user;
  const _ActionsCard({required this.user});

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Settings',
    child: Column(
      children: [
        const PushNotificationSwitch(),
        _ActionRow(
          icon: Icons.lock_outline,
          label: 'Change password',
          onTap: () => _openChangePassword(context),
        ),
        _ActionRow(
          icon: user.twoFactorEnabled
              ? Icons.shield_rounded
              : Icons.shield_outlined,
          label: user.twoFactorEnabled
              ? 'Disable two-factor auth'
              : 'Enable two-factor auth',
          labelColor: user.twoFactorEnabled
              ? const Color(0xFF15803D)
              : null,
          trailing: user.twoFactorEnabled
              ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('ON',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D))))
              : null,
          onTap: () => user.twoFactorEnabled
              ? _openDisable2FA(context)
              : _openSetup2FA(context),
        ),
      ],
    ),
  );

  void _openChangePassword(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) =>  Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 0,
            insetPadding: EdgeInsets.symmetric(horizontal: 24),
            child:_ChangePasswordSheet()));
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
// ─── Activity Card ────────────────────────────────────────

class _ActivitiesCard extends StatelessWidget {
  final UserModel user;
  const _ActivitiesCard({required this.user});

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Activities',
    child: Column(
      children: [
        _ActionRow(
          icon: Icons.calendar_month_rounded,
          label: 'My Calender',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CalendarScreen())),
        ),
        _ActionRow(
          icon: Icons.file_copy,
          label: 'Case Achieve (Logs)',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CasesScreen())),
        ),
      ],
    ),
  );
}
// ─── Support Card ────────────────────────────────────────

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Support & FAQs',
    child: Column(
      children: [
        _ActionRow(
          icon: Icons.support_agent,
          label: 'Contact Support',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SupportScreen())),
        ),
        _ActionRow(
          icon: Icons.help_outline_outlined,
          label: 'FAQs',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => FaqScreen())),
        ),
        _ActionRow(
          icon: Icons.request_page_rounded,
          label: 'Suport Page',
          onTap: () async {
            final uri = Uri.parse('https://trabajohub.com/support');

            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                mode: LaunchMode.inAppBrowserView,
              );
            }
          },
          // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => TicketHistoryScreen())),
        ),
      ],
    ),
  );
}

class _DeleteAccountCard extends ConsumerWidget {
  final UserModel user;
  const _DeleteAccountCard({required this.user, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      title: 'Danger zone',
      child: Column(
        children: [
          const Text(
            'Delete your account permanently. This will remove all your data and sign you out of the app.',
            style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showDeleteAccountDialog(context, ref),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                foregroundColor: const Color(0xFFB91C1C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 24),
          child: const _DeleteAccountSheet(),
    ));
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Widget? trailing;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF536C79)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: labelColor ?? const Color(0xFF1A2632))),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: Color(0xFF94A3B4)),
        ],
      ),
    ),
  );
}

// ─── Logout Button ───────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: OutlinedButton.icon(
      onPressed: onLogout,
      icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFE24B4A)),
      label: const Text(
        'Log out',
        style: TextStyle(fontSize: 15, color: Color(0xFFE24B4A), fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE24B4A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

// ─── Reusable Section Card ───────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8EDF2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B4),
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet({super.key});

  @override
  ConsumerState<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _error;
  bool _isLoading = false;

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

    final success = await ref.read(authProvider.notifier).deleteAccount(
          password: password,
          reason: reason.isEmpty ? null : reason,
        );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignIn()),
        (_) => false,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _error = ref.read(authProvider).error ?? 'Unable to delete account.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottom + 24),
      decoration:  BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delete account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A2632)),
          ),
          const SizedBox(height: 10),
          const Text(
            'This action is permanent. Enter your password to confirm account deletion.',
            style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Current password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for leaving (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Delete account',style: TextStyle(color: Colors.white),),
                ),
              ),
            ],
          ),
          SizedBox(height: 24,)
        ],
      ),
    );
  }
}

// ─── Edit Profile Bottom Sheet ───────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserModel user;
  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final np = widget.user.nurseProfile;
    _firstName = TextEditingController(text: np?.firstName ?? '');
    _lastName = TextEditingController(text: np?.lastName ?? '');
    _phone = TextEditingController(text: widget.user.phone ?? '');
    _bio = TextEditingController(text: np?.bio ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref.read(authProvider.notifier).updateProfile({
      if (_firstName.text.trim().isNotEmpty) 'firstName': _firstName.text.trim(),
      if (_lastName.text.trim().isNotEmpty) 'lastName': _lastName.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_bio.text.trim().isNotEmpty) 'bio': _bio.text.trim(),
    });
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profile updated' : ref.read(authProvider).error ?? 'Update failed'),
        backgroundColor: success ? const Color(0xFF0F6E56) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A2632)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _SheetField(controller: _firstName, label: 'First name')),
              const SizedBox(width: 12),
              Expanded(child: _SheetField(controller: _lastName, label: 'Last name')),
            ],
          ),
          const SizedBox(height: 12),
          _SheetField(controller: _phone, label: 'Phone', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _SheetField(controller: _bio, label: 'Bio', maxLines: 3),
          const SizedBox(height: 20),
          Button(
              buttonText: "Save changes",
              onPressed: isLoading ? null : _save,
              isLoading:isLoading
          )
        ],
      ),
    );
  }
}

// ─── Change Password Bottom Sheet ────────────────────────

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newPw.text != _confirmPw.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    final success = await ref.read(authProvider.notifier).changePassword(
      currentPassword: _currentPw.text,
      newPassword: _newPw.text,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Password changed' : ref.read(authProvider).error ?? 'Failed'),
        backgroundColor: success ? const Color(0xFF0F6E56) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Change password',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A2632)),
          ),
          const SizedBox(height: 20),
          _SheetField(
            controller: _currentPw,
            label: 'Current password',
            obscureText: _obscureCurrent,
            suffixIcon: IconButton(
              icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
          const SizedBox(height: 12),
          _SheetField(
            controller: _newPw,
            label: 'New password',
            obscureText: _obscureNew,
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 12),
          _SheetField(
            controller: _confirmPw,
            label: 'Confirm new password',
            obscureText: true,
          ),
          const SizedBox(height: 20),
          Button(
              buttonText: "Update password",
              onPressed: isLoading ? null : _submit,
              isLoading:isLoading
          ),
        ],
      ),
    );
  }
}

// ─── Shared Sheet Field ──────────────────────────────────

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B4),
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A2632)),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF7F8FA),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8ED)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8ED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0A9FBF), width: 1.5),
          ),
        ),
      ),
    ],
  );
}