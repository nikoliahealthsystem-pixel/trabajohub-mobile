import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trabajo_hub/active_session.dart';
import 'package:trabajo_hub/features/billing/presentation/wallet_screen.dart';
import 'package:trabajo_hub/features/credentials/presentation/credentials_screen.dart';
import 'package:trabajo_hub/features/messaging/presentation/chat_detail_screen.dart';
import 'package:trabajo_hub/features/messaging/providers/messaging_provider.dart';
import 'package:trabajo_hub/features/shifts/presentation/shift_detail_screen.dart';
import 'package:trabajo_hub/features/visits/presentation/visit_detail_screen.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../state/notifications_notifier.dart';
import '../state/notifications_state.dart';
import 'widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  final Set<String> _selectedIds = <String>{};

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).load(refresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(notificationsProvider);

      if (state.hasMore && state.status == NotificationsStatus.success) {
        ref.read(notificationsProvider.notifier).load();
      }
    }
  }

  String? _dataString(NotificationModel notification, String key) {
    final value = notification.data?[key];

    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  String _event(NotificationModel notification) {
    return (_dataString(notification, 'notificationEvent') ??
            _dataString(notification, 'event') ??
            '')
        .toUpperCase();
  }

  Future<void> _openNotification(NotificationModel notification) async {
    final notifier = ref.read(notificationsProvider.notifier);

    if (!notification.isRead) {
      await notifier.markOneRead(notification.id);
    }

    if (!mounted) {
      return;
    }

    await _navigateForNotification(notification);
  }

  Future<void> _navigateForNotification(NotificationModel notification) async {
    final event = _event(notification);

    final shiftId = _dataString(notification, 'shiftId');

    final visitId = _dataString(notification, 'visitId');

    final conversationId = _dataString(notification, 'conversationId');

    final isMessage =
        notification.type == NotificationType.newMessage ||
        event == 'NEW_MESSAGE';

    final isCredential =
        notification.type == NotificationType.credentialApproved ||
        notification.type == NotificationType.credentialRejected ||
        notification.type == NotificationType.credentialExpiry ||
        event.contains('CREDENTIAL');

    final isPayment =
        notification.type == NotificationType.paymentAlert ||
        event.contains('PAYMENT') ||
        event.contains('PAYOUT') ||
        event.contains('EARNING');

    final isVisit =
        visitId != null || event.contains('VISIT') || event.contains('EVV');

    final isShift =
        shiftId != null ||
        notification.type == NotificationType.shiftAlert ||
        notification.type == NotificationType.assignmentUpdate ||
        notification.type == NotificationType.shiftCancelled ||
        notification.type == NotificationType.bookingConfirmation ||
        event.contains('SHIFT') ||
        event.contains('ASSIGNMENT') ||
        event.contains('BOOKING');

    if (isMessage) {
      await _openMessage(conversationId);
      return;
    }

    if (isCredential) {
      if (!mounted) {
        return;
      }

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CredentialsScreen()));
      return;
    }

    if (isPayment) {
      if (!mounted) {
        return;
      }

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const WalletScreen()));
      return;
    }

    if (isVisit) {
      if (!mounted) {
        return;
      }

      if (visitId != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VisitDetailScreen(visitId: visitId),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 2)),
        );
      }

      return;
    }

    if (isShift) {
      if (!mounted) {
        return;
      }

      if (shiftId != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShiftDetailScreen(shiftId: shiftId),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 1)),
        );
      }

      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 0)),
    );
  }

  Future<void> _openMessage(String? conversationId) async {
    if (conversationId == null) {
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 3)),
      );

      return;
    }

    final messagingNotifier = ref.read(messagingProvider.notifier);

    await messagingNotifier.loadConversations(silent: true);

    final messagingState = ref.read(messagingProvider);

    final matching = messagingState.conversations
        .where((conversation) => conversation.id == conversationId)
        .toList();

    if (matching.isEmpty) {
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 3)),
      );

      return;
    }

    await messagingNotifier.selectConversation(matching.first);

    if (!mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatDetailScreen()));
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    if (_selectedIds.isEmpty) {
      return;
    }

    setState(_selectedIds.clear);
  }

  void _selectAllVisibleUnread(NotificationsState state) {
    final unreadIds = state.items
        .where((item) => !item.isRead)
        .map((item) => item.id)
        .toSet();

    setState(() {
      _selectedIds
        ..clear()
        ..addAll(unreadIds);
    });
  }

  Future<void> _markSelectedRead(NotificationsState state) async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final notifier = ref.read(notificationsProvider.notifier);

    final unreadSelected = state.items
        .where((item) => _selectedIds.contains(item.id) && !item.isRead)
        .map((item) => item.id)
        .toList();

    for (final id in unreadSelected) {
      await notifier.markOneRead(id);
    }

    if (!mounted) {
      return;
    }

    _clearSelection();
  }

  Future<void> _markAllRead(NotificationsNotifier notifier) async {
    await notifier.markAllRead();

    if (!mounted) {
      return;
    }

    _clearSelection();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    final notifier = ref.read(notificationsProvider.notifier);

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectionMode) {
          _clearSelection();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: Column(
          children: [
            _buildHeader(context, state, notifier),

            _buildFilterBar(state, notifier),

            Expanded(child: _buildBody(state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    NotificationsState state,
    NotificationsNotifier notifier,
  ) {
    return Container(
      decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 12,
        18,
        16,
      ),
      child: _selectionMode
          ? _buildSelectionHeader(state)
          : Row(
              children: [
                _HeaderButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.total} total ? ${state.unreadCount} unread',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),

                if (state.unreadCount > 0)
                  _HeaderTextButton(
                    text: 'Mark all read',
                    loading: state.isMarkingAll,
                    onTap: state.isMarkingAll
                        ? null
                        : () => _markAllRead(notifier),
                  ),
              ],
            ),
    );
  }

  Widget _buildSelectionHeader(NotificationsState state) {
    final selectedUnread = state.items
        .where((item) => _selectedIds.contains(item.id) && !item.isRead)
        .length;

    return Row(
      children: [
        _HeaderButton(icon: Icons.close_rounded, onTap: _clearSelection),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedIds.length} selected',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$selectedUnread unread selected',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),

        if (selectedUnread > 0)
          _HeaderTextButton(
            text: 'Mark read',
            onTap: () => _markSelectedRead(state),
          ),
      ],
    );
  }

  Widget _buildFilterBar(
    NotificationsState state,
    NotificationsNotifier notifier,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          _TabChip(
            label: 'All',
            isActive: !state.unreadOnly,
            onTap: () {
              if (_selectionMode) {
                _clearSelection();
              }

              if (state.unreadOnly) {
                notifier.toggleUnreadOnly();
              }
            },
          ),

          const SizedBox(width: 8),

          _TabChip(
            label: 'Unread',
            isActive: state.unreadOnly,
            badge: state.unreadCount > 0 ? state.unreadCount : null,
            onTap: () {
              if (_selectionMode) {
                _clearSelection();
              }

              if (!state.unreadOnly) {
                notifier.toggleUnreadOnly();
              }
            },
          ),

          const Spacer(),

          if (!_selectionMode && state.items.any((item) => !item.isRead))
            TextButton.icon(
              onPressed: () => _selectAllVisibleUnread(state),
              icon: const Icon(Icons.checklist_rounded, size: 17),
              label: const Text('Select'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0A7D95),
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(NotificationsState state, NotificationsNotifier notifier) {
    if (state.status == NotificationsStatus.loading && state.items.isEmpty) {
      return const _NotificationsLoading();
    }

    if (state.status == NotificationsStatus.error && state.items.isEmpty) {
      return _NotificationsError(
        message: state.errorMessage ?? 'Unable to load notifications.',
        onRetry: () => notifier.load(refresh: true),
      );
    }

    if (state.items.isEmpty) {
      return _NotificationsEmpty(unreadOnly: state.unreadOnly);
    }

    return RefreshIndicator(
      color: const Color(0xFF0A9FBF),
      onRefresh: () async {
        _clearSelection();

        await notifier.load(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 10, bottom: 28),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0A9FBF),
                ),
              ),
            );
          }

          final item = state.items[index];

          final selected = _selectedIds.contains(item.id);

          return NotificationTile(
            notification: item,
            selected: selected,
            selectionMode: _selectionMode,

            onTap: () => _openNotification(item),

            onLongPress: () => _toggleSelection(item.id),

            onSelectionTap: () => _toggleSelection(item.id),

            onMarkRead: item.isRead
                ? null
                : () {
                    notifier.markOneRead(item.id);
                  },
          );
        },
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }
}

class _HeaderTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool loading;

  const _HeaderTextButton({
    required this.text,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF8FC) : const Color(0xFFF2F4F7),
          border: Border.all(
            color: isActive ? const Color(0xFF0A9FBF) : const Color(0xFFE4E7EC),
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? const Color(0xFF0A7D95)
                    : const Color(0xFF667085),
              ),
            ),

            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A9FBF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          height: 112,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
        );
      },
    );
  }
}

class _NotificationsEmpty extends StatelessWidget {
  final bool unreadOnly;

  const _NotificationsEmpty({required this.unreadOnly});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF8FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 33,
                color: Color(0xFF0A9FBF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              unreadOnly ? 'You?re all caught up' : 'No notifications yet',
              style: const TextStyle(
                color: Color(0xFF1D2939),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              unreadOnly
                  ? 'There are no unread notifications right now.'
                  : 'Important TrabajoHub updates will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _NotificationsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFB42318),
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load notifications',
              style: TextStyle(
                color: Color(0xFF1D2939),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 11.5),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Try again',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A9FBF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
