import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';

// Per-type icon and colour config
const _typeConfig = {
  NotificationType.shiftAlert: (Icons.schedule_rounded, Color(0xFF3B82F6)),
  NotificationType.bookingConfirmation: (Icons.check_circle_outline_rounded, Color(0xFF10B981)),
  NotificationType.credentialExpiry: (Icons.badge_outlined, Color(0xFFF59E0B)),
  NotificationType.assignmentUpdate: (Icons.assignment_outlined, Color(0xFF8B5CF6)),
  NotificationType.paymentAlert: (Icons.account_balance_wallet_outlined, Color(0xFF0A9FBF)),
  NotificationType.systemAlert: (Icons.info_outline_rounded, Color(0xFF536C79)),
  NotificationType.credentialApproved: (Icons.verified_outlined, Color(0xFF10B981)),
  NotificationType.credentialRejected: (Icons.cancel_outlined, Color(0xFFEF4444)),
  NotificationType.shiftCancelled: (Icons.event_busy_outlined, Color(0xFFEF4444)),
  NotificationType.newMessage: (Icons.chat_bubble_outline_rounded, Color(0xFF0A9FBF)),
};

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig[notification.type] ??
        (Icons.notifications_outlined, const Color(0xFF536C79));
    final icon = config.$1;
    final color = config.$2;
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isUnread ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? color.withOpacity(0.2) : const Color(0xFFE8EDF2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Type label
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notification.type.label.toUpperCase(),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: 0.4),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(notification.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B4)),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
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
                    const SizedBox(height: 5),
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                        isUnread ? FontWeight.w700 : FontWeight.w600,
                        color: const Color(0xFF1A2632),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF536C79),
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}