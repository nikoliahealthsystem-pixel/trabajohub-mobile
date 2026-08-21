// lib/shared/widgets/notifications_bell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../../../features/notifications/presentation/notifications_screen.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
import '../../../features/notifications/state/notifications_state.dart';

class NotificationsBell extends ConsumerWidget {
  final Color iconColor;
  const NotificationsBell({super.key, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load on first build
    ref.listen(notificationsProvider.select((s) => s.status), (_, status) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(notificationsProvider);
      if (state.status == NotificationsStatus.initial) {
        ref.read(notificationsProvider.notifier).load(refresh: true);
      }
    });

    final unread = ref.watch(unreadCountProvider);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset(
              'assets/svg/notifications.svg',
              width: 28,
              height: 28,
              color: iconColor,
            ),
            if (unread > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints:
                  const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}