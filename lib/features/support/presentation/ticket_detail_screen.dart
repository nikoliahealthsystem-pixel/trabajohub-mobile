import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../data/models/support_ticket.dart';
import '../providers/ticket_detail_provider.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ticketDetailProvider(widget.ticketId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketDetailProvider(widget.ticketId));
    final ticket = state.ticket;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(ticket),
          Expanded(
            child: state.isLoading && ticket == null
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? _buildError(state.error!)
                : _buildConversation(ticket!),
          ),
          if (ticket != null && ticket.status != "CLOSED")
            _buildReplyBox(state),
        ],
      ),
    );
  }

  Widget _buildHeader(TicketDetail? ticket) => Container(
    decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
    padding: EdgeInsets.fromLTRB(
        20, MediaQuery.of(context).padding.top + 14, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            const Spacer(),
            if (ticket != null) _StatusBadge(status: ticket.status),
          ],
        ),

        const SizedBox(height: 16),

        // Ticket Number + Priority
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket?.ticketNumber ?? "Loading...",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (ticket != null)
                    Text(
                      ticket.subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Meta info
        if (ticket != null)
          Row(
            children: [
              Text(
                ticket.category.replaceAll("_", " "),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),

        if (ticket != null)
          Text(
            DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(ticket.createdAt),
            style: const TextStyle(color: Colors.white60, fontSize: 12.5),
          ),
      ],
    ),
  );


  Widget _buildConversation(TicketDetail ticket) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: ticket.replies.length,
        itemBuilder: (context, index) {
          final reply = ticket.replies[index];

          return _MessageBubble(reply: reply);
        },
    );
  }

  Widget _buildError(String error) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
        const SizedBox(height: 16),
        const Text("Failed to load ticket", style: TextStyle(fontSize: 18)),
        Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => ref.read(ticketDetailProvider(widget.ticketId).notifier).load(),
          child: const Text("Retry"),
        ),
      ],
    ),
  );

  Widget _buildReplyBox(TicketDetailState state) {
    final notifier = ref.read(ticketDetailProvider(widget.ticketId).notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              maxLines: 4,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: "Write a reply...",
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              if (_replyController.text.trim().isEmpty) return;
              await notifier.addReply(_replyController.text.trim());
              _replyController.clear();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0A7D95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Status Badge
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    String statusText = status == "WAITING_ON_USER" ? "AWAITING USER":status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText.replaceAll("_", " "),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFF1E40AF);
      case 'IN_PROGRESS':
        return const Color(0xFFB45309);
      case 'RESOLVED':
        return const Color(0xFF15803D);
      case 'CLOSED':
        return const Color(0xFF475569);
      default:
        return const Color(0xFF64748B);
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketReply reply;

  const _MessageBubble({super.key, required this.reply});

  @override
  Widget build(BuildContext context) {
    final bool isMe = !reply.isStaff; // Nurses are not staff
    final String displayName = reply.authorName?.isNotEmpty == true
        ? reply.authorName!
        : isMe ? "You" : "Support";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender label
            Padding(
              padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isMe ? const Color(0xFF0A7D95) : const Color(0xFF475569),
                    ),
                  ),
                  if (reply.isInternal)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Text(
                        "Internal",
                        style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),

            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: isMe
                    ? accentColor
                    : reply.isInternal
                    ? const Color(0xFFFEF3C7)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(6),
                  bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(18),
                ),
                border: (!isMe && !reply.isInternal)
                    ? Border.all(color: const Color(0xFFE2E8F0))
                    : null,
              ),
              child: Text(
                reply.body,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.45,
                  color: isMe ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 8, right: 8),
              child: Text(
                DateFormat('MMM d • h:mm a').format(reply.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}