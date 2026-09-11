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

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
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
      ..loadMessageableRecipients();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child: _NewConversationSheet(
          searchController: _searchController,
          onConversationStarted: () => Navigator.pop(context),
        ),
      ),
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
              minHeight: 2,
              color: Color(0xFF0A9FBF),
            ),
          Expanded(child: _buildBody(state, currentUserId)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MessagingState state) => Container(
    decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
    padding: EdgeInsets.fromLTRB(
      16,
      MediaQuery.of(context).padding.top + 12,
      16,
      16,
    ),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messaging',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Stay connected with your team',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        // Unread badge
        if (state.unreadCount > 0)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${state.unreadCount} unread',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 18,
            ),
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
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 52,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'No conversations yet.',
              style: TextStyle(color: Colors.grey),
            ),
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
      onRefresh: () => ref.read(messagingProvider.notifier).loadConversations(),
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
              ref.read(messagingProvider.notifier).selectConversation(conv);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatDetailScreen(user: conv.otherParticipant!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ New conversation bottom sheet Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

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

enum _RecipientCategory { facilityStaff, support, recent, nurses }

class _NewConversationSheetState extends ConsumerState<_NewConversationSheet> {
  _RecipientCategory? _selectedCategory;
  String _filter = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(messagingProvider.notifier).loadMessageableRecipients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagingProvider);
    final notifier = ref.read(messagingProvider.notifier);

    final allContacts = state.userSearchResults;

    List<UserSearchResult> contactsFor(_RecipientCategory category) {
      switch (category) {
        case _RecipientCategory.facilityStaff:
          return allContacts
              .where(
                (contact) =>
                    contact.role == 'FACILITY_ADMIN' ||
                    contact.role == 'TEAM_MEMBER',
              )
              .toList();

        case _RecipientCategory.support:
          return allContacts
              .where(
                (contact) =>
                    contact.role == 'SUPER_ADMIN' ||
                    contact.role == 'OPERATIONS_MANAGER' ||
                    contact.role == 'RECRUITER',
              )
              .toList();

        case _RecipientCategory.nurses:
          return allContacts
              .where((contact) => contact.role == 'NURSE')
              .toList();

        case _RecipientCategory.recent:
          // Recent contacts are currently included in the secure
          // endpoint and may overlap the role-based groups.
          // Until state keeps a dedicated recent group, show all
          // authorized contacts here.
          return allContacts;
      }
    }

    final currentContacts = _selectedCategory == null
        ? const <UserSearchResult>[]
        : contactsFor(_selectedCategory!);

    final filteredContacts = _filter.trim().isEmpty
        ? currentContacts
        : currentContacts.where((contact) {
            final query = _filter.toLowerCase();

            return contact.displayName.toLowerCase().contains(query) ||
                contact.subtitle.toLowerCase().contains(query) ||
                contact.role.toLowerCase().contains(query);
          }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE3E8),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              if (_selectedCategory != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _filter = '';
                      widget.searchController.clear();
                    });
                    notifier.clearRecipient();
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: Color(0xFF1A2632),
                  ),
                ),

              if (_selectedCategory != null) const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCategory == null
                          ? 'Who would you like to talk to?'
                          : _categoryTitle(_selectedCategory!),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15202B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _selectedCategory == null
                          ? 'Only authorized TrabajoHub contacts are shown.'
                          : 'Choose a person to start a secure conversation.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFF71808D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (state.isSearchingUsers)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF0A9FBF),
                ),
              ),
            )
          else if (_selectedCategory == null)
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _CategoryCard(
                      icon: Icons.local_hospital_outlined,
                      title: 'Facility Staff',
                      subtitle: 'Staff from facilities connected to your work',
                      count: contactsFor(
                        _RecipientCategory.facilityStaff,
                      ).length,
                      onTap: () {
                        setState(() {
                          _selectedCategory = _RecipientCategory.facilityStaff;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    _CategoryCard(
                      icon: Icons.support_agent_rounded,
                      title: 'TrabajoHub Support',
                      subtitle: 'Operations, compliance and recruiting',
                      count: contactsFor(_RecipientCategory.support).length,
                      onTap: () {
                        setState(() {
                          _selectedCategory = _RecipientCategory.support;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    _CategoryCard(
                      icon: Icons.history_rounded,
                      title: 'Recent Contacts',
                      subtitle: 'Continue with people you already know',
                      count: contactsFor(_RecipientCategory.recent).length,
                      onTap: () {
                        setState(() {
                          _selectedCategory = _RecipientCategory.recent;
                        });
                      },
                    ),

                    if (contactsFor(_RecipientCategory.nurses).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _CategoryCard(
                        icon: Icons.medical_services_outlined,
                        title: 'Nurses',
                        subtitle: 'Nurses you are authorized to contact',
                        count: contactsFor(_RecipientCategory.nurses).length,
                        onTap: () {
                          setState(() {
                            _selectedCategory = _RecipientCategory.nurses;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            TextField(
              controller: widget.searchController,
              decoration: InputDecoration(
                hintText: 'Filter this list...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF8796A3),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F7F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filter = value;
                });
              },
            ),

            const SizedBox(height: 12),

            Flexible(
              child: filteredContacts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'No contacts available in this category.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF8796A3),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredContacts.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Color(0xFFEDF1F4)),
                      itemBuilder: (_, index) {
                        final contact = filteredContacts[index];

                        return _RecipientTile(
                          contact: contact,
                          isStarting:
                              state.isStartingConversation &&
                              state.selectedRecipient?.id == contact.id,
                          onTap: () async {
                            notifier.selectRecipient(contact);

                            final success = await notifier.startConversation();

                            if (!context.mounted || !success) {
                              return;
                            }

                            widget.onConversationStarted();

                            if (!context.mounted) {
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  username: contact.displayName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],

          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFB42318)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _categoryTitle(_RecipientCategory category) {
    switch (category) {
      case _RecipientCategory.facilityStaff:
        return 'Facility Staff';
      case _RecipientCategory.support:
        return 'TrabajoHub Support';
      case _RecipientCategory.recent:
        return 'Recent Contacts';
      case _RecipientCategory.nurses:
        return 'Nurses';
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7FA),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF087F98), size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17232E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: Color(0xFF758592),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF536C79),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  final UserSearchResult contact;
  final bool isStarting;
  final VoidCallback onTap;

  const _RecipientTile({
    required this.contact,
    required this.isStarting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isStarting ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: const Color(0xFFE7F3F6),
              child: Text(
                contact.displayName.isEmpty
                    ? '?'
                    : contact.displayName[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF087F98),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17232E),
                    ),
                  ),
                  if (contact.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact.subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF748490),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isStarting)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0A9FBF),
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFB0BBC3),
              ),
          ],
        ),
      ),
    );
  }
}
