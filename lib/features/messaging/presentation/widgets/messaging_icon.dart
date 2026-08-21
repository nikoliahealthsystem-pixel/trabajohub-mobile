import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/constants/app_constants.dart';

import '../../providers/messaging_provider.dart' show messagingProvider; // adjust path/name if different

/// Messaging icon (for an AppBar action or bottom nav) with an unread-count
/// badge sourced from MessagingState.unreadCount.
class MessagingIconButton extends ConsumerWidget {
  final Color iconColor;
  final String iconPath;

  const MessagingIconButton({
    super.key, required this.iconColor, required this.iconPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(messagingProvider.select((s) => s.unreadCount));

    return Badge(
      // Hide entirely when there's nothing unread.
      isLabelVisible: unreadCount > 0,
      label: Text(
        unreadCount > 99 ? '99+' : '$unreadCount',
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
      ),
      backgroundColor: Colors.red,
      child: SvgPicture.asset(
        'assets/$iconPath',
        width: 28,
        height: 28,
        color: iconColor,
      ),
    );
  }
}