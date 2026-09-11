import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../state/notification_preferences_state.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  static const Color _background = Color(0xFFF6F8FB);
  static const Color _heading = Color(0xFF101828);

  bool _pushDeviceReady = false;
  bool _checkingPushDevice = true;
  bool _savingPushDevice = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(notificationPreferencesProvider.notifier).load();
      await _refreshPushDeviceState();
    });
  }

  Future<void> _refreshPushDeviceState() async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!mounted) return;

      setState(() {
        _pushDeviceReady = authorized;
        _checkingPushDevice = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _pushDeviceReady = false;
        _checkingPushDevice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationPreferencesProvider);

    ref.listen(notificationPreferencesProvider, (previous, next) {
      final message = next.errorMessage;

      if (message != null &&
          message.isNotEmpty &&
          message != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB42318),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _heading),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notification preferences',
          style: TextStyle(
            color: _heading,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEAECF0)),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationPreferencesState state) {
    if (state.isLoading && state.preferences == null) {
      return const _LoadingView();
    }

    if (state.status == NotificationPreferencesStatus.error &&
        state.preferences == null) {
      return _ErrorView(
        message:
            state.errorMessage ??
            'Unable to load your notification preferences.',
        onRetry: () {
          ref.read(notificationPreferencesProvider.notifier).load();
        },
      );
    }

    final preferences = state.preferences;

    if (preferences == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () =>
          ref.read(notificationPreferencesProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
        children: [
          _HeroCard(
            pushEnabled: preferences.pushEnabled,
            emailEnabled: preferences.emailEnabled,
          ),

          const SizedBox(height: 26),

          const _SectionHeader(
            title: 'Delivery channels',
            subtitle: 'Choose how TrabajoHub is allowed to reach you.',
          ),

          const SizedBox(height: 12),

          _PreferenceGroup(
            children: [
              _PreferenceTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push notifications',
                subtitle: _checkingPushDevice
                    ? 'Checking this device notification permission...'
                    : !_pushDeviceReady
                    ? 'Notifications are currently blocked on this device.'
                    : 'Receive important alerts directly on this device.',
                value: preferences.pushEnabled && _pushDeviceReady,
                saving: state.savingField == 'pushEnabled' || _savingPushDevice,
                onChanged: _updatePushNotifications,
              ),
            ],
          ),

          const SizedBox(height: 26),

          const _SectionHeader(
            title: 'Shifts & scheduling',
            subtitle:
                'Control alerts related to opportunities and assigned work.',
          ),

          const SizedBox(height: 12),

          _PreferenceGroup(
            children: [
              _item(
                state,
                field: 'shiftOffersEnabled',
                icon: Icons.work_outline_rounded,
                title: 'Shift offers',
                subtitle:
                    'New shifts that match your designation and availability.',
                value: preferences.shiftOffersEnabled,
              ),
              const _PreferenceDivider(),
              _item(
                state,
                field: 'assignmentUpdatesEnabled',
                icon: Icons.assignment_outlined,
                title: 'Assignment updates',
                subtitle: 'Changes to shifts you have booked or been assigned.',
                value: preferences.assignmentUpdatesEnabled,
              ),
              const _PreferenceDivider(),
              _item(
                state,
                field: 'shiftRemindersEnabled',
                icon: Icons.alarm_outlined,
                title: 'Shift reminders',
                subtitle: 'Helpful reminders before an upcoming shift.',
                value: preferences.shiftRemindersEnabled,
              ),
              const _PreferenceDivider(),
              _item(
                state,
                field: 'shiftCancellationsEnabled',
                icon: Icons.event_busy_outlined,
                title: 'Shift cancellations',
                subtitle:
                    'Immediate notice when an assigned shift is cancelled.',
                value: preferences.shiftCancellationsEnabled,
              ),
              const _PreferenceDivider(),
              _item(
                state,
                field: 'urgentShiftsEnabled',
                icon: Icons.bolt_outlined,
                title: 'Urgent shifts',
                subtitle:
                    'Time-sensitive and emergency staffing opportunities.',
                value: preferences.urgentShiftsEnabled,
              ),
            ],
          ),

          const SizedBox(height: 26),

          const _SectionHeader(
            title: 'Visits & EVV',
            subtitle:
                'Stay informed about visit activity and verification issues.',
          ),

          const SizedBox(height: 12),

          _PreferenceGroup(
            children: [
              _item(
                state,
                field: 'evvExceptionsEnabled',
                icon: Icons.location_off_outlined,
                title: 'EVV exceptions',
                subtitle:
                    'Clock-in, location or verification issues requiring attention.',
                value: preferences.evvExceptionsEnabled,
              ),
              const _PreferenceDivider(),
              _item(
                state,
                field: 'visitUpdatesEnabled',
                icon: Icons.route_outlined,
                title: 'Visit updates',
                subtitle:
                    'Important changes affecting scheduled or completed visits.',
                value: preferences.visitUpdatesEnabled,
              ),
            ],
          ),

          const SizedBox(height: 26),

          const _SectionHeader(
            title: 'Earnings & payouts',
            subtitle: 'Choose which financial updates you want to receive.',
          ),

          const SizedBox(height: 12),

          _PreferenceGroup(
            children: [
              _item(
                state,
                field: 'earningsEnabled',
                icon: Icons.payments_outlined,
                title: 'Earnings',
                subtitle: 'Earnings approval and balance updates.',
                value: preferences.earningsEnabled,
              ),
              const _PreferenceDivider(),
              _item(
                state,
                field: 'payoutsEnabled',
                icon: Icons.account_balance_wallet_outlined,
                title: 'Payouts',
                subtitle: 'Payment processing, sent and payout status alerts.',
                value: preferences.payoutsEnabled,
              ),
            ],
          ),

          const SizedBox(height: 26),

          const _SectionHeader(
            title: 'Credentials',
            subtitle: 'Keep your professional requirements current.',
          ),

          const SizedBox(height: 12),

          _PreferenceGroup(
            children: [
              _item(
                state,
                field: 'credentialUpdatesEnabled',
                icon: Icons.verified_outlined,
                title: 'Credential updates',
                subtitle: 'Approval, rejection and review decisions.',
                value: preferences.credentialUpdatesEnabled,
              ),
              const _PreferenceDivider(),
              _item(
                state,
                field: 'credentialExpiryEnabled',
                icon: Icons.event_available_outlined,
                title: 'Credential expiry',
                subtitle: 'Warnings before an important credential expires.',
                value: preferences.credentialExpiryEnabled,
              ),
            ],
          ),

          const SizedBox(height: 26),

          const _SectionHeader(
            title: 'Messages',
            subtitle: 'Manage notifications for TrabajoHub conversations.',
          ),

          const SizedBox(height: 12),

          _PreferenceGroup(
            children: [
              _item(
                state,
                field: 'messagesEnabled',
                icon: Icons.chat_bubble_outline_rounded,
                title: 'New messages',
                subtitle:
                    'Be notified when you receive a new TrabajoHub message.',
                value: preferences.messagesEnabled,
              ),
            ],
          ),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Color(0xFF667085),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Critical account and security notices may still be delivered when necessary to protect your account.',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 11.5,
                      height: 1.45,
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

  Widget _item(
    NotificationPreferencesState state, {
    required String field,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
  }) {
    return _PreferenceTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      value: value,
      saving: state.savingField == field,
      onChanged: (next) => _update(field, next),
    );
  }

  Future<void> _updatePushNotifications(bool enable) async {
    if (_savingPushDevice) return;

    setState(() => _savingPushDevice = true);

    try {
      final messaging = FirebaseMessaging.instance;

      if (enable) {
        // 1. Ask Android for notification permission.
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        final authorized =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

        if (!authorized) {
          if (mounted) {
            setState(() => _pushDeviceReady = false);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Notification permission is required to enable push notifications.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          return;
        }

        // 2. Obtain this physical device's FCM token.
        final token = await messaging.getToken();

        if (token == null || token.trim().isEmpty) {
          throw Exception(
            'TrabajoHub could not register this device for notifications.',
          );
        }

        // 3. Register the device with the authenticated TrabajoHub account.
        final registered = await ref
            .read(authProvider.notifier)
            .updateFcmToken(token);

        if (!registered) {
          throw Exception(
            'TrabajoHub could not register this device for notifications.',
          );
        }

        // 4. Enable the user's push delivery preference.
        final preferenceSaved = await ref
            .read(notificationPreferencesProvider.notifier)
            .updateField('pushEnabled', true);

        if (!preferenceSaved) {
          // Roll back the backend device registration because the complete
          // enable operation did not succeed.
          await ref.read(authProvider.notifier).updateFcmToken('');
          throw Exception('TrabajoHub could not enable push notifications.');
        }

        if (mounted) {
          setState(() => _pushDeviceReady = true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Push notifications enabled'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // 1. Disable delivery preference first.
        final preferenceSaved = await ref
            .read(notificationPreferencesProvider.notifier)
            .updateField('pushEnabled', false);

        if (!preferenceSaved) {
          throw Exception('TrabajoHub could not disable push notifications.');
        }

        // 2. Remove this device from the TrabajoHub account.
        final backendCleared = await ref
            .read(authProvider.notifier)
            .updateFcmToken('');

        if (!backendCleared) {
          // Restore the preference because device deregistration failed.
          await ref
              .read(notificationPreferencesProvider.notifier)
              .updateField('pushEnabled', true);

          throw Exception('TrabajoHub could not unregister this device.');
        }

        // 3. Delete the local Firebase token only after backend success.
        await messaging.deleteToken();

        if (mounted) {
          setState(() => _pushDeviceReady = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Push notifications disabled'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      await _refreshPushDeviceState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB42318),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingPushDevice = false);
      }
    }
  }

  Future<void> _update(String field, bool value) async {
    await ref
        .read(notificationPreferencesProvider.notifier)
        .updateField(field, value);
  }
}

class _HeroCard extends StatelessWidget {
  final bool pushEnabled;
  final bool emailEnabled;
  const _HeroCard({required this.pushEnabled, required this.emailEnabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor, const Color(0xFF2D4855)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: .18),
            blurRadius: 26,
            offset: const Offset(0, 10),
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
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Stay informed your way',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fine-tune which TrabajoHub updates reach you and how they are delivered.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .80),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 17),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChannelBadge(
                icon: Icons.notifications_outlined,
                label: 'Push',
                active: pushEnabled,
              ),
              _ChannelBadge(
                icon: Icons.email_outlined,
                label: 'Email',
                active: emailEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _ChannelBadge({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? .18 : .08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: active ? .22 : .10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _PreferenceGroup extends StatelessWidget {
  final List<Widget> children;

  const _PreferenceGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final bool unavailable;
  final bool saving;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.unavailable = false,
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: unavailable
                  ? const Color(0xFFF2F4F7)
                  : accentColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 19,
              color: unavailable ? const Color(0xFF98A2B3) : accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: unavailable
                              ? const Color(0xFF667085)
                              : const Color(0xFF344054),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (unavailable) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'UNAVAILABLE',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (saving)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
              ),
            )
          else
            Switch.adaptive(
              value: value,
              activeTrackColor: accentColor,
              onChanged: enabled ? onChanged : null,
            ),
        ],
      ),
    );
  }
}

class _PreferenceDivider extends StatelessWidget {
  const _PreferenceDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 67, color: Color(0xFFEAECF0));
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: List.generate(
        6,
        (index) => Container(
          height: index == 0 ? 170 : 110,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
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
                Icons.notifications_off_outlined,
                color: Color(0xFFB42318),
                size: 27,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load preferences',
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 17,
                fontWeight: FontWeight.w800,
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
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
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
}
