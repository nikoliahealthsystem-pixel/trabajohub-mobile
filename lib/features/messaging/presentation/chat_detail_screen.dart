import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/features/messaging/presentation/widgets/compact_avatar.dart';
import 'package:trabajo_hub/features/messaging/presentation/widgets/participant_modal.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/socket/socket_connection_notifier.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/models/conversation_model.dart';
import '../providers/messaging_provider.dart';
import '../state/messaging_state.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_dots.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final ConversationParticipant? user;
  final String? username;
  const ChatDetailScreen({super.key, this.user, this.username});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // ── Pending attachment state ─────────────────────────────────
  PlatformFile? _pendingFile;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(messagingProvider);
      if (state.selectedConversation != null && state.messages.isEmpty) {
        ref.read(messagingProvider.notifier)
            .selectConversation(state.selectedConversation!);
      }
      final currentUserId = ref.read(currentUserProvider)?.id ?? '';
      _markUnreadMessagesAsRead(currentUserId);
    });
    _loadInitialMessages();
    _scrollToBottom();
  }

  void _onMessageChanged(String value) {
    if (value.isNotEmpty) {
      ref.read(messagingProvider.notifier).sendTyping();
    }
  }

  void _loadInitialMessages() {
    final state = ref.read(messagingProvider);
    final conversation = state.selectedConversation;
    if (conversation != null && state.messages.isEmpty) {
      ref.read(messagingProvider.notifier).selectConversation(conversation);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100 &&
        ref.read(messagingProvider).hasMoreMessages) {
      ref.read(messagingProvider.notifier).loadMoreMessages();
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Send: handles both plain text AND file-with-caption ──────
  Future<void> _handleSend() async {
    final text = _messageController.text.trim();

    // ── Case 1: file is pending — upload with optional caption
    if (_pendingFile != null) {
      final file = _pendingFile!;
      final caption = text.isEmpty ? null : text;

      _messageController.clear();
      setState(() => _pendingFile = null);

      if (file.path == null) return;

      final ok = await ref.read(messagingProvider.notifier).uploadAttachment(
        filePath: file.path!,
        fileName: file.name,
        mimeType: file.extension != null
            ? 'application/${file.extension}'
            : 'application/octet-stream',
        caption: caption,
      );
      if (ok) _scrollToBottom();
      return;
    }

    // ── Case 2: plain text message
    if (text.isEmpty) return;
    _messageController.clear();
    final success = await ref.read(messagingProvider.notifier).sendMessage(text);
    if (success) _scrollToBottom();
  }

  // ── Attach: stage the file, don't upload yet ─────────────────
  Future<void> _handleAttach() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() => _pendingFile = file);
    // Focus the text field so user can type a caption immediately
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _clearPendingFile() {
    setState(() => _pendingFile = null);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagingProvider);
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id ?? '';
    final conversation = state.selectedConversation;

    if (conversation == null) {
      return const Scaffold(
        body: Center(child: Text('No conversation selected')),
      );
    }

    ref.listen<int>(
      messagingProvider.select((s) => s.messages.length),
          (_, __) {
        _scrollToBottom();
        _markUnreadMessagesAsRead(currentUserId);
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(context, state, widget.username, widget.user),
          if (state.hasMoreMessages) _buildLoadMoreButton(),
          Expanded(child: _buildMessageList(state, currentUserId)),
          if (state.typingUserId != null &&
              state.typingConversationId == state.selectedConversation?.id)
            _buildTypingIndicator(),
          if (state.sendError != null)
            _buildErrorBanner(state.sendError!.length < 20
                ? '${state.sendError}'
                : 'Unable To Send'),
          // File preview chip sits above the input bar
          if (_pendingFile != null) _buildFilePreviewBar(),
          _buildInputBar(state),
        ],
      ),
    );
  }
  void _markUnreadMessagesAsRead(String currentUserId) {
    final messages = ref.read(messagingProvider).messages;
    final notifier = ref.read(messagingProvider.notifier);

    for (final msg in messages) {
      if (msg.senderId != currentUserId && msg.status != 'READ' && !msg.isDeleted) {
        notifier.markMessageRead(msg.id);
      }
    }
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context,
      MessagingState state,
      String? otherUserName,
      ConversationParticipant? user
      ) {

    final  initials = otherUserName?.trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return GestureDetector(
      onTap: ()=> user !=null ? showParticipantDetailsModal(
        context,
        user,
      ):null,
        child: Container(
      decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
      padding: EdgeInsets.fromLTRB(
          12, MediaQuery.of(context).padding.top + 10, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ref.read(messagingProvider.notifier).clearSelectedConversation();
              Navigator.pop(context);
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          user != null?
          CompactAvatar(
            user: user,
            radius: 18,
          ):
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(initials??"",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? otherUserName ?? "",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Consumer(
                  builder: (_, ref, __) {
                    final socketStatus = ref.watch(socketConnectionProvider);
                    final isLive = socketStatus == SocketStatus.connected;
                    return Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: isLive
                                ? const Color(0xFF28D744)
                                : const Color(0xFF94A3B4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          isLive ? 'Live' : 'Reconnecting…',
                          style: TextStyle(
                            color:
                            isLive ? Colors.white70 : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  // ── Load more ────────────────────────────────────────────────

  Widget _buildLoadMoreButton() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () =>
            ref.read(messagingProvider.notifier).loadMoreMessages(),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8ED)),
          ),
          child: const Text('Load older messages',
              style:
              TextStyle(fontSize: 12, color: Color(0xFF536C79))),
        ),
      ),
    ),
  );

  // ── Message list ─────────────────────────────────────────────

  Widget _buildMessageList(MessagingState state, String currentUserId) {
    final isLoading =
        state.status == MessageFetchStatus.loading && state.messages.isEmpty;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0A9FBF)),
      );
    }

    if (state.messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet.\nSay something!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: state.messages.length,
      itemBuilder: (_, index) {
        final msg = state.messages[index];
        final isMe = msg.senderId == currentUserId;
        return MessageBubble(
          message: msg,
          isMe: isMe,
          isDeleting: state.deletingMessageId == msg.id,
          onDelete: () => _confirmDelete(msg.id),
          onMarkRead: () =>
              ref.read(messagingProvider.notifier).markMessageRead(msg.id),
        );
      },
    );
  }

  // ── File preview bar (shown above input when file is staged) ─

  Widget _buildFilePreviewBar() {
    final file = _pendingFile!;
    final ext = (file.extension ?? '').toUpperCase();
    final isImage = ['JPG', 'JPEG', 'PNG', 'GIF', 'WEBP'].contains(ext);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon / thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
              color: const Color(0xFF0A9FBF),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          // File name + size
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2632),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (file.size > 0)
                  Text(
                    _formatFileSize(file.size),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B4)),
                  ),
              ],
            ),
          ),
          // Dismiss
          GestureDetector(
            onTap: _clearPendingFile,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: Color(0xFF536C79)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ── Error banner ─────────────────────────────────────────────

  Widget _buildErrorBanner(String error) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(error,
                style: const TextStyle(
                    color: Colors.red, fontSize: 13))),
        GestureDetector(
          onTap: () => ref.read(messagingProvider.notifier).clearError(),
          child: const Icon(Icons.close, size: 16, color: Colors.red),
        ),
      ],
    ),
  );

  // ── Typing indicator ─────────────────────────────────────────

  Widget _buildTypingIndicator() => Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 4),
    child: Row(
      children: [
        TypingDots(),
        const SizedBox(width: 8),
        const Text(
          'typing…',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B4),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );

  // ── Input bar ────────────────────────────────────────────────

  Widget _buildInputBar(MessagingState state) => Container(
    padding: EdgeInsets.fromLTRB(
        12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
    decoration: const BoxDecoration(
      color: Colors.white,
      border:
      Border(top: BorderSide(color: Color(0xFFE8EDF2), width: 1)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Attach — hidden once a file is already staged
        if (_pendingFile == null)
          GestureDetector(
            onTap: state.isUploading ? null : _handleAttach,
            child: Container(
              width: 38,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: state.isUploading
                  ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF0A9FBF)),
              )
                  : const Icon(Icons.attach_file_rounded,
                  size: 22, color: Color(0xFF536C79)),
            ),
          ),
        if (_pendingFile == null) const SizedBox(width: 8),
        // Text input — hint adapts to context
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8ED)),
            ),
            child: TextField(
              controller: _messageController,
              onChanged: _onMessageChanged,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1A2632)),
              decoration: InputDecoration(
                // Hint changes when a file is staged
                hintText: _pendingFile != null
                    ? 'Add a caption…'
                    : 'Type a message…',
                hintStyle: const TextStyle(
                    color: Color(0xFF94A3B4), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => _handleSend(),
              textInputAction: TextInputAction.send,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Send
        GestureDetector(
          onTap: state.isSending || state.isUploading
              ? null
              : _handleSend,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: (state.isSending || state.isUploading)
                  ? null
                  : ColorConstants.appGradient,
              color: (state.isSending || state.isUploading)
                  ? const Color(0xFFE2E8ED)
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: (state.isSending || state.isUploading)
                ? const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.send_rounded,
                color: Colors.white, size: 22),
          ),
        ),
      ],
    ),
  );

  // ── Delete confirm ───────────────────────────────────────────

  Future<void> _confirmDelete(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This cannot be undone.'),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
            const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(messagingProvider.notifier).deleteMessage(messageId);
    }
  }
}