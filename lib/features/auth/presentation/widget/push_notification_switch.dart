import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/core/cache/app_cache.dart';
import 'package:trabajo_hub/features/auth/providers/auth_provider.dart';

class PushNotificationSwitch extends ConsumerStatefulWidget {
  const PushNotificationSwitch({super.key});

  @override
  ConsumerState<PushNotificationSwitch> createState() => _PushNotificationSwitchState();
}

class _PushNotificationSwitchState extends ConsumerState<PushNotificationSwitch> {
  bool _isEnabled = false;
  bool _isLoading = false;

  static const String _fcmRegisteredKey = 'fcmTokenRegistered';

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final isRegistered = AppCache.instance.getValue<bool>(_fcmRegisteredKey) ?? false;

    setState(() {
      _isEnabled = settings.authorizationStatus == AuthorizationStatus.authorized && isRegistered;
    });
  }

  Future<void> _toggleNotifications() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final messaging = FirebaseMessaging.instance;

      if (_isEnabled) {
        // === DISABLE ===
        await messaging.deleteToken();

        final success = await ref.read(authProvider.notifier).updateFcmToken('');

        if (success) {
          AppCache.instance.invalidate(_fcmRegisteredKey);
          setState(() => _isEnabled = false);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Push notifications disabled'),
                  behavior: SnackBarBehavior.floating),
            );
          }
        }
      } else {
        // === ENABLE ===
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification permission was denied'),
              behavior: SnackBarBehavior.floating,),
            );
          }
          return;
        }

        final token = await messaging.getToken();
        if (token == null) {
          throw Exception("Failed to generate FCM token");
        }

        final success = await ref.read(authProvider.notifier).updateFcmToken(token);

        if (success) {
          // Store with 30 days TTL (you can adjust)
          AppCache.instance.set<bool>(
            _fcmRegisteredKey,
            true,
            const Duration(days: 30),
          );

          setState(() => _isEnabled = true);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Push notifications enabled'),
                  behavior: SnackBarBehavior.floating),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text(
        'Push notifications',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A2632)),
      ),
      subtitle: const Text(
        'Get notified about new Trabajo Hub activities',
        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B4)),
      ),
      secondary: const Icon(Icons.notifications_outlined, color: Color(0xFF536C79),size: 18,),
      value: _isEnabled,
      onChanged: _isLoading ? null : (_) => _toggleNotifications(),
      activeTrackColor: const Color(0xFF0A9FBF).withOpacity(0.4),
      activeColor: const Color(0xFF0A9FBF),
    );
  }
}