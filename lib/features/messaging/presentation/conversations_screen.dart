import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/buttons/notification_button.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/messaging_provider.dart';
import '../state/messaging_state.dart';
import 'chat_detail_screen.dart';
import 'widgets/conversation_tile.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState
    extends ConsumerState<ConversationsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Always check if the widget is still mounted before
      //    interacting with providers that trigger state changes.
      if (!mounted) return;

      ref.read(messagingProvider.notifier)
        ..loadConversations()
        ..startPolling();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Stop polling only if we're fully leaving messaging
    // ref.read(messagingProvider.notifier).stopPolling();
    super.dispose();
  }

  void _openNewConversationSheet() {
    _searchController.clear();
    ref.read(messagingProvider.notifier)
      ..clearRecipient()
      ..searchUsers('');

    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) =>  Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 24),
          child: _NewConversationSheet(
        searchController: _searchController,
        onConversationStarted: () => Navigator.pop(context),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagingProvider);
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(context, state),
          if (state.status == MessagingStatus.loading &&
              state.conversations.isEmpty)
            const LinearProgressIndicator(
                minHeight: 2, color: Color(0xFF0A9FBF)),
          Expanded(child: _buildBody(state, currentUserId)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MessagingState state) =>
      Container(
        decoration: const BoxDecoration(
          gradient: ColorConstants.appGradient,
        ),
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + 12, 16, 16),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Messaging',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  Text('Stay connected with your team',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            // Unread badge
            if (state.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.unreadCount} unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            // New conversation button
            GestureDetector(
              onTap: _openNewConversationSheet,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: Colors.white, size: 18),
              ),
            ),
            const NotificationsBell(),
          ],
        ),
      );

  Widget _buildBody(MessagingState state, String currentUserId) {
    if (state.conversations.isEmpty &&
        state.status != MessagingStatus.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No conversations yet.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            const Text(
              'Tap the pencil icon to start one.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0A9FBF),
      onRefresh: () =>
          ref.read(messagingProvider.notifier).loadConversations(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.conversations.length,
        itemBuilder: (_, i) {
          final conv = state.conversations[i];
          return ConversationTile(
            conversation: conv,
            isSelected: false,
            currentUserId: currentUserId,
            onTap: () {
              ref
                  .read(messagingProvider.notifier)
                  .selectConversation(conv);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(user: conv.otherParticipant!,),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── New conversation bottom sheet ─────────────────────────────────────

class _NewConversationSheet extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final VoidCallback onConversationStarted;

  const _NewConversationSheet({
    required this.searchController,
    required this.onConversationStarted,
  });

  @override
  ConsumerState<_NewConversationSheet> createState() =>
      _NewConversationSheetState();
}

class _NewConversationSheetState
    extends ConsumerState<_NewConversationSheet> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagingProvider);
    final notifier = ref.read(messagingProvider.notifier);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration:  BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('New conversation',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2632))),
          const SizedBox(height: 14),

          // Search field
          TextField(
            controller: widget.searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search by name or email…',
              prefixIcon:
              const Icon(Icons.search, color: Color(0xFF94A3B4)),
              suffixIcon: widget.searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: Color(0xFF94A3B4)),
                onPressed: () {
                  widget.searchController.clear();
                  notifier
                    ..clearRecipient()
                    ..searchUsers('');
                  setState(() {});
                },
              )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Color(0xFFE2E8ED))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Color(0xFFE2E8ED))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF007AFF), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
            onChanged: (v) {
              notifier.searchUsers(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 8),

          // Search results
          if (state.isSearchingUsers)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2))),
            )
          else if (state.selectedRecipient == null &&
              state.userSearchResults.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Container(
                decoration: BoxDecoration(
                  border:
                  Border.all(color: const Color(0xFFE2E8ED)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.userSearchResults.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, color: Color(0xFFEEF1F4)),
                  itemBuilder: (_, i) {
                    final user = state.userSearchResults[i];
                    return InkWell(
                      onTap: () {
                        notifier.selectRecipient(user);
                        widget.searchController.text =
                            user.displayName;
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                              const Color(0xFFE8EDF2),
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0]
                                    .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF536C79)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(user.displayName,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A2632))),
                                  if (user.subtitle.isNotEmpty)
                                    Text(user.subtitle,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                            Color(0xFF94A3B4))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ] else if (state.selectedRecipient == null &&
              widget.searchController.text.trim().length >= 2 &&
              !state.isSearchingUsers &&
              state.userSearchResults.isEmpty) ...[
            const SizedBox(height: 8),
            const Center(
              child: Text('No users found.',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF94A3B4))),
            ),
          ],

          // Selected recipient chip
          if (state.selectedRecipient != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: const Color(0xFF007AFF)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF007AFF),
                    child: Text(
                      state.selectedRecipient!.displayName
                          .isNotEmpty
                          ? state.selectedRecipient!.displayName[0]
                          .toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.selectedRecipient!.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1A2632)),
                        ),
                        if (state.selectedRecipient!.subtitle
                            .isNotEmpty)
                          Text(
                            state.selectedRecipient!.subtitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF536C79)),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      notifier.clearRecipient();
                      widget.searchController.clear();
                      setState(() {});
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF536C79)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: state.isStartingConversation
                    ? null
                    : () async {
                  final success = await notifier.startConversation();

                  if (success && context.mounted) {
                    // Close the bottom sheet
                    widget.onConversationStarted();

                    // Small delay to allow state to update and avoid navigation glitches
                    // await Future.delayed(const Duration(milliseconds: 5));

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(username: state.selectedRecipient?.displayName,),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: state.isStartingConversation
                    ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                    : const Text('Start conversation',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}