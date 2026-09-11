import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class PrivacyDataScreen extends ConsumerStatefulWidget {
  const PrivacyDataScreen({super.key});

  @override
  ConsumerState<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends ConsumerState<PrivacyDataScreen> {
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://trabajohub.com/privacy-policy',
  );

  static final Uri _termsOfServiceUri = Uri.parse(
    'https://trabajohub.com/terms-of-service',
  );

  bool _exporting = false;

  Future<void> _openLegalPage(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Unable to open this page right now.'),
              backgroundColor: Color(0xFFB42318),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to open this page right now.'),
            backgroundColor: Color(0xFFB42318),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _exportData() async {
    if (_exporting) return;

    setState(() {
      _exporting = true;
    });

    var stage = 'starting export';

    try {
      stage = 'requesting account data';

      final repository = ref.read(authRepositoryProvider);

      final data = await repository.exportMyData();

      stage = 'encoding account data';

      final jsonText = const JsonEncoder.withIndent('  ').convert(data);

      stage = 'creating export file';

      final directory = await getTemporaryDirectory();

      final now = DateTime.now();

      final stamp =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}-'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      final file = File(
        '${directory.path}'
        '${Platform.pathSeparator}'
        'trabajohub-data-$stamp.json',
      );

      await file.writeAsString(jsonText, flush: true);

      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      if (!exists || size == 0) {
        throw StateError('The export file could not be created.');
      }

      if (!mounted) return;

      stage = 'opening the share sheet';

      final renderObject = context.findRenderObject();

      final box = renderObject is RenderBox ? renderObject : null;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'My TrabajoHub data export',
          text: 'Your TrabajoHub account data export.',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Your data export is ready.'),
            backgroundColor: Color(0xFF027A48),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error, stackTrace) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Unable to export your data while $stage.'),
            backgroundColor: const Color(0xFFB42318),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Privacy & data',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEAECF0)),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
          children: [
            _PrivacyHero(),

            const SizedBox(height: 22),

            const _SectionLabel('YOUR DATA'),

            const SizedBox(height: 8),

            _PrivacyCard(
              children: [
                _PrivacyAction(
                  icon: Icons.download_rounded,
                  title: 'Export my data',
                  subtitle:
                      'Download a copy of the account information TrabajoHub stores about you.',
                  trailing: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: Color(0xFF98A2B3),
                        ),
                  onTap: _exporting ? null : _exportData,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 19,
                    color: Color(0xFF0A7D95),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your export does not include passwords, authentication secrets, full bank account numbers, internal staff notes or internal security metadata.',
                      style: TextStyle(
                        color: Color(0xFF344054),
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const _SectionLabel('WHAT WE STORE'),

            const SizedBox(height: 8),

            const _PrivacyCard(
              children: [
                _DataCategory(
                  icon: Icons.person_outline_rounded,
                  title: 'Account & profile',
                  subtitle:
                      'Contact details, professional profile, verification status and credentials.',
                ),
                _Divider(),
                _DataCategory(
                  icon: Icons.work_outline_rounded,
                  title: 'Work activity',
                  subtitle:
                      'Shift assignments, visits, EVV activity and survey responses.',
                ),
                _Divider(),
                _DataCategory(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Earnings & payouts',
                  subtitle:
                      'Wallet balances, transaction history and payout records.',
                ),
                _Divider(),
                _DataCategory(
                  icon: Icons.notifications_none_rounded,
                  title: 'Communications',
                  subtitle:
                      'Notifications, messages and support requests associated with your account.',
                ),
              ],
            ),

            const SizedBox(height: 24),

            const _SectionLabel('ACCOUNT PRIVACY'),

            const SizedBox(height: 8),

            const _PrivacyCard(
              children: [
                _InformationRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Protected information',
                  body:
                      'Authentication credentials and sensitive payment information remain protected and are not included in account exports.',
                ),
                _Divider(),
                _InformationRow(
                  icon: Icons.delete_outline_rounded,
                  title: 'Account deletion',
                  body:
                      'You can request account deletion from your profile. Your account is deactivated immediately and scheduled for permanent deletion after the applicable grace period.',
                ),
              ],
            ),

            const SizedBox(height: 24),

            const _SectionLabel('LEGAL'),

            const SizedBox(height: 8),

            _PrivacyCard(
              children: [
                _PrivacyAction(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy policy',
                  subtitle:
                      'Learn how TrabajoHub collects, uses, and protects your information.',
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: Color(0xFF98A2B3),
                  ),
                  onTap: () => _openLegalPage(_privacyPolicyUri),
                ),
                const _Divider(),
                _PrivacyAction(
                  icon: Icons.description_outlined,
                  title: 'Terms of service',
                  subtitle:
                      'Review the terms that govern your use of TrabajoHub.',
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: Color(0xFF98A2B3),
                  ),
                  onTap: () => _openLegalPage(_termsOfServiceUri),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ColorConstants.appGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
          ),
          const SizedBox(height: 15),
          const Text(
            'Your information, under your control',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Review how your account information is handled and export a copy of the data associated with your TrabajoHub account.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .82),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF667085),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: .8,
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final List<Widget> children;

  const _PrivacyCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _PrivacyAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _PrivacyAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _IconBox(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _DataCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DataCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 10.5,
                    height: 1.4,
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

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InformationRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 10.5,
                    height: 1.45,
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

class _IconBox extends StatelessWidget {
  final IconData icon;

  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8FC),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF0A7D95)),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 64, color: Color(0xFFEAECF0));
  }
}
