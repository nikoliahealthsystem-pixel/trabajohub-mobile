import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/attachment_preview_screen.dart';
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isDeleting;
  final VoidCallback onDelete;
  final VoidCallback onMarkRead;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isDeleting,
    required this.onDelete,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Text(
              isMe ? 'You' : (message.sender?.displayName ?? 'Unknown'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF536C79),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFE8EDF2),
                  child: Text(
                    (message.sender?.displayName ?? '?')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF536C79)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: _buildBubble(context),
              ),
            ],
          ),
          // Meta row
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.createdAt),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B4)),
                ),
                if (isMe && !message.isDeleted) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                  const SizedBox(width: 6),
                  if (isDeleting)
                    const SizedBox(
                      width: 10, height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF94A3B4)),
                    )
                  else
                    GestureDetector(
                      onTap: onDelete,
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B4)),
                      ),
                    ),
                ],
                if (!isMe && message.status != 'READ' && !message.isDeleted) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onMarkRead,
                    child:  Text(
                      'Mark read',
                      style: TextStyle(fontSize: 10, color: accentColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    if (message.isDeleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: const Text(
          'This message was deleted',
          style: TextStyle(
            fontSize: 13, color: Color(0xFF94A3B4),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: message.attachmentSignedUrl != null ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: isMe ? accentColor : Colors.white,
        border: isMe ? null : Border.all(color: const Color(0xFFE8EDF2)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.content != null && message.content!.isNotEmpty)
            Text(
              message.content!,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : const Color(0xFF1A2632),
                height: 1.4,
              ),
            ),
          if (message.attachmentSignedUrl != null) ...[
            if (message.content != null && message.content!.isNotEmpty)
              const SizedBox(height: 8),
            _buildAttachment(context),
          ],
        ],
      ),
    );
  }

  Future<void> _launchAttachment(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openPreview(BuildContext context, String url, String fileName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7,
            child: AttachmentPreviewScreen(
              url: url,
              fileName: fileName,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachment(BuildContext context) {
    // Resolve a display name from the URL if the model doesn't carry fileName
    final fileName = Uri.parse(message.attachmentSignedUrl!).pathSegments.last;

    if (message.isImage) {
      return GestureDetector(
        onTap: () => _openPreview(context, message.attachmentSignedUrl!, fileName),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: message.attachmentSignedUrl!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 180,
              color: const Color(0xFFE8EDF2),
              child: const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF0A9FBF)),
              ),
            ),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openPreview(context, message.attachmentSignedUrl!, fileName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withOpacity(0.15)
              : const Color(0xFFF0F4F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 18,
                color: isMe ? Colors.white70 : const Color(0xFF536C79)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : const Color(0xFF0A9FBF),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.visibility_outlined,
                size: 14,
                color: isMe ? Colors.white54 : const Color(0xFF94A3B4)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (message.status == 'READ') {
      return const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF0A9FBF));
    }
    if (message.status == 'DELIVERED') {
      return const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF94A3B4));
    }
    return const Icon(Icons.done_rounded, size: 14, color: Color(0xFF94A3B4));
  }
}