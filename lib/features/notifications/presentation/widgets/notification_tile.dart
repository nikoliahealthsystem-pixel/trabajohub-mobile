import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/notification_model.dart';

const _typeConfig = {
  NotificationType.shiftAlert: (Icons.schedule_rounded, Color(0xFF3B82F6)),
  NotificationType.bookingConfirmation: (
    Icons.check_circle_outline_rounded,
    Color(0xFF10B981),
  ),
  NotificationType.credentialExpiry: (Icons.badge_outlined, Color(0xFFF59E0B)),
  NotificationType.assignmentUpdate: (
    Icons.assignment_outlined,
    Color(0xFF8B5CF6),
  ),
  NotificationType.paymentAlert: (
    Icons.account_balance_wallet_outlined,
    Color(0xFF0A9FBF),
  ),
  NotificationType.systemAlert: (Icons.info_outline_rounded, Color(0xFF536C79)),
  NotificationType.credentialApproved: (
    Icons.verified_outlined,
    Color(0xFF10B981),
  ),
  NotificationType.credentialRejected: (
    Icons.cancel_outlined,
    Color(0xFFEF4444),
  ),
  NotificationType.shiftCancelled: (
    Icons.event_busy_outlined,
    Color(0xFFEF4444),
  ),
  NotificationType.newMessage: (
    Icons.chat_bubble_outline_rounded,
    Color(0xFF0A9FBF),
  ),
};

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onSelectionTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.onMarkRead,
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
    this.onSelectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final config =
        _typeConfig[notification.type] ??
        (Icons.notifications_outlined, const Color(0xFF536C79));

    final icon = config.$1;
    final color = config.$2;
    final isUnread = !notification.isRead;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selectionMode ? onSelectionTap : onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE8F7FB)
              : isUnread
              ? color.withValues(alpha: .05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF0A9FBF)
                : isUnread
                ? color.withValues(alpha: .20)
                : const Color(0xFFE4E7EC),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06101828),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? const Color(0xFF0A9FBF) : Colors.white,
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF0A9FBF)
                            : const Color(0xFFD0D5DD),
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 15,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
              ],

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notification.type.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: .35,
                            ),
                          ),
                        ),

                        const Spacer(),

                        Text(
                          _formatTime(notification.createdAt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF98A2B3),
                          ),
                        ),

                        if (isUnread) ...[
                          const SizedBox(width: 7),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isUnread
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: const Color(0xFF1D2939),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF667085),
                        height: 1.42,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (!selectionMode && isUnread && onMarkRead != null) ...[
                      const SizedBox(height: 9),
                      InkWell(
                        onTap: onMarkRead,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: .16),
                            ),
                          ),
                          child: Text(
                            'Mark as read',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }

    return DateFormat('MMM d').format(dt);
  }
}
