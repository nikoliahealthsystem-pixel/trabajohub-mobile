import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/active_session.dart';
import 'package:trabajo_hub/features/credentials/presentation/credentials_screen.dart';
import 'package:trabajo_hub/features/messaging/presentation/conversations_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/presentation/profile_screen.dart';
import '../../shifts/presentation/my_shifts_screen.dart';
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

class _NotificationsScreenState
    extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(notificationsProvider);
      if (state.hasMore &&
          state.status == NotificationsStatus.success) {
        ref.read(notificationsProvider.notifier).load();
      }
    }
  }
  // ── Routing ────────────────────────────────────────────────

  void _navigateForNotification(NotificationModel notification) {
    final Widget destination;

    switch (notification.type) {
      case NotificationType.newMessage:
        destination = const ActiveSession(pageIndex: 3);
        break;

      case NotificationType.shiftAlert:
      case NotificationType.assignmentUpdate:
      case NotificationType.shiftCancelled:
      case NotificationType.bookingConfirmation:
        destination = const ActiveSession(pageIndex: 1);
        break;

      case NotificationType.credentialExpiry:
      case NotificationType.credentialApproved:
      case NotificationType.credentialRejected:
        destination = const CredentialsScreen();
        break;

      case NotificationType.paymentAlert:
      case NotificationType.systemAlert:
        destination = const ActiveSession(pageIndex: 4);
        break;
    }

    if (!mounted) return;

    final isCredentialNotification = {
      NotificationType.credentialApproved,
      NotificationType.credentialExpiry,
      NotificationType.credentialRejected,
    }.contains(notification.type);

    if (isCredentialNotification) {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => destination));
    } else {
      Navigator.of(context)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => destination), (_) => false);
    }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(context, state, notifier),
          _buildFilterBar(state, notifier),
          Expanded(child: _buildBody(state, notifier)),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context,
      NotificationsState state,
      NotificationsNotifier notifier,
      ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: ColorConstants.appGradient,
      ),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 14, 20, 18),
      child: Row(
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
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notifications',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
                Text(
                  '${state.total} total · ${state.unreadCount} unread',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Mark all read
          if (state.unreadCount > 0)
            GestureDetector(
              onTap: state.isMarkingAll ? null : notifier.markAllRead,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: state.isMarkingAll
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Mark all read',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Filter bar ───────────────────────────────────────────────

  Widget _buildFilterBar(
      NotificationsState state,
      NotificationsNotifier notifier,
      ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _TabChip(
            label: 'All',
            isActive: !state.unreadOnly,
            onTap: () {
              if (state.unreadOnly) notifier.toggleUnreadOnly();
            },
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: 'Unread',
            isActive: state.unreadOnly,
            badge: state.unreadCount > 0 ? state.unreadCount : null,
            onTap: () {
              if (!state.unreadOnly) notifier.toggleUnreadOnly();
            },
          ),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────

  Widget _buildBody(
      NotificationsState state,
      NotificationsNotifier notifier,
      ) {
    if (state.status == NotificationsStatus.loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A9FBF)));
    }

    if (state.status == NotificationsStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Color(0xFFE24B4A)),
            const SizedBox(height: 12),

            Text(state.errorMessage!.length  < 50 ? "${state.errorMessage}" : 'Something went wrong',
                style: const TextStyle(color: Color(0xFF536C79))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.load(refresh: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A9FBF)),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8FC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.notifications_off_outlined,
                  size: 44, color: Color(0xFF0A9FBF)),
            ),
            const SizedBox(height: 14),
            Text(
              state.unreadOnly
                  ? 'No unread notifications'
                  : 'No notifications yet',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2632),
                  fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'You\'re all caught up!',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B4)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0A9FBF),
      onRefresh: () => notifier.load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 10, bottom: 24),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF0A9FBF))),
            );
          }
          final item = state.items[i];
          return NotificationTile(
            notification: item,
            onTap: () {
              if (!item.isRead) notifier.markOneRead(item.id);
              _navigateForNotification(item);
            },
          );
        },
      ),
    );
  }
}

// ── Tab chip ──────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFEAF8FC)
            : const Color(0xFFF0F4F7),
        border: Border.all(
          color: isActive
              ? const Color(0xFF0A9FBF)
              : const Color(0xFFE2E8ED),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFF0A7D95)
                  : const Color(0xFF536C79),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF0A9FBF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}