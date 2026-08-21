import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/support_ticket.dart';

class TicketTile extends StatelessWidget {
  final TicketListItem ticket;
  final VoidCallback onTap;

  const TicketTile({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getStatusColor(ticket.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.$2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon / Status Circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.$1,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(ticket.status),
                      color: colorScheme.$2,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Main Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ticket.ticketNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            _StatusBadge(status: ticket.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticket.subject,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2937),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Meta info
                        Row(
                          children: [
                            Text(
                              ticket.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('MMM d, yyyy').format(ticket.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),

                        if (ticket.replyCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  "${ticket.replyCount} replies",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B4), size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  (Color, Color) _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return (const Color(0xFFDBEAFE), const Color(0xFF1E40AF));
      case 'IN_PROGRESS':
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309));
      case 'WAITING_ON_USER':
        return (const Color(0xFFF3E8FF), const Color(0xFF6B21A8));
      case 'RESOLVED':
        return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
      case 'CLOSED':
        return (const Color(0xFFF1F5F9), const Color(0xFF475569));
      default:
        return (const Color(0xFFE2E8F0), const Color(0xFF64748B));
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'OPEN':
        return Icons.support_agent;
      case 'IN_PROGRESS':
        return Icons.hourglass_top;
      case 'WAITING_ON_USER':
        return Icons.person_outline;
      case 'RESOLVED':
        return Icons.check_circle_outline;
      case 'CLOSED':
        return Icons.lock_outline;
      default:
        return Icons.help_outline;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor(status);
    String statusText = status == "WAITING_ON_USER" ? "AWAITING USER":status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.$1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.$2,
        ),
      ),
    );
  }

  (Color, Color) _getBadgeColor(String status) {
    switch (status) {
      case 'OPEN':
        return (const Color(0xFF3B82F6), const Color(0xFF1E40AF));
      case 'IN_PROGRESS':
        return (const Color(0xFFF59E0B), const Color(0xFFB45309));
      case 'RESOLVED':
        return (const Color(0xFF10B981), const Color(0xFF15803D));
      case 'CLOSED':
        return (const Color(0xFF64748B), const Color(0xFF334155));
      default:
        return (const Color(0xFF94A3B4), const Color(0xFF475569));
    }
  }
}