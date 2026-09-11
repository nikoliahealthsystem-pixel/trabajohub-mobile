import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/socket/socket_client.dart';
import '../../../core/socket/socket_events.dart';
import '../data/messaging_repository.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';
import 'messaging_state.dart';

class MessagingNotifier extends StateNotifier<MessagingState> {
  final MessagingRepository _repo;
  final SocketClient _socket;
  final AppCache _cache;

  Timer? _pollTimer;
  Timer? _searchDebounce;
  Timer? _typingTimer;

  // Track which conversation room we're currently in
  String? _activeConversationId;

  MessagingNotifier(this._repo, this._socket, this._cache)
    : super(const MessagingState()) {
    _attachSocketListeners();
    _socket.onConnect(() {
      if (_activeConversationId != null) {
        joinConversation(_activeConversationId!);
      }
    });
  }

  // â”€â”€ Socket listeners â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _attachSocketListeners() {
    // New message arrives in the active conversation
    _socket.on(SocketEvents.newMessage, (data) {
      final message = MessageModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      );

      // â”€â”€ DEDUP: skip if we already have this message in state â”€â”€
      final alreadyExists = state.messages.any((m) => m.id == message.id);
      if (alreadyExists) return;

      // Only inject if it belongs to the active conversation
      if (state.selectedConversation?.id == message.conversationId) {
        state = state.copyWith(messages: [...state.messages, message]);
      }

      // Bust caches + refresh conversation list
      _cache.invalidate(CacheKeys.messages(message.conversationId));
      _cache.invalidatePrefix(CacheKeys.prefixConversations);
      loadConversations(silent: true);
    });

    // Someone is typing
    _socket.on(SocketEvents.userTyping, (data) {
      final d = Map<String, dynamic>.from(data as Map);
      final userId = d['userId'] as String?;
      final convId = d['conversationId'] as String?;

      if (convId == state.selectedConversation?.id && userId != null) {
        state = state.copyWith(
          typingUserId: userId,
          typingConversationId: convId,
        );
        // Clear typing indicator after 3 seconds
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          state = state.copyWith(
            typingUserId: null,
            typingConversationId: null,
          );
        });
      }
    });

    // Message marked read by the other participant
    _socket.on(SocketEvents.messageRead, (data) {
      final d = Map<String, dynamic>.from(data as Map);
      final messageId = d['messageId'] as String?;
      if (messageId == null) return;
      state = state.copyWith(
        messages: state.messages
            .map((m) => m.id == messageId ? m.copyWith(status: 'READ') : m)
            .toList(),
      );
    });

    // Message deleted by sender
    _socket.on(SocketEvents.messageDeleted, (data) {
      final d = Map<String, dynamic>.from(data as Map);
      final messageId = d['messageId'] as String?;
      if (messageId == null) return;
      state = state.copyWith(
        messages: state.messages
            .map(
              (m) => m.id == messageId
                  ? m.copyWith(
                      content: null,
                      attachmentUrl: null,
                      attachmentKey: null,
                      attachmentSignedUrl: null,
                    )
                  : m,
            )
            .toList(),
      );
    });
  }

  // â”€â”€ Polling (fallback when socket is not connected) â”€â”€â”€â”€â”€â”€â”€â”€

  void startPolling() {
    // Don't poll if socket is connected â€” events handle updates
    if (_socket.isConnected) return;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadConversations(silent: true);
      final conv = state.selectedConversation;
      if (conv != null) _reloadMessages(conv.id);
    });
  }

  void stopPolling() => _pollTimer?.cancel();

  // â”€â”€ Conversations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> loadConversations({bool silent = false}) async {
    if (!silent) state = state.copyWith(status: MessagingStatus.loading);
    try {
      final result = await _repo.getConversations();
      final unread = await _repo.getUnreadCount();
      state = state.copyWith(
        status: MessagingStatus.success,
        conversations: result.conversations,
        unreadCount: unread,
      );
    } catch (e) {
      final msg = e is DioException
          ? (e.message ?? 'Something went wrong')
          : e.toString();
      if (!silent) {
        state = state.copyWith(
          status: MessagingStatus.error,
          errorMessage: msg,
        );
      }
    }
  }

  // â”€â”€ Select conversation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> selectConversation(ConversationModel conversation) async {
    // 1. Leave previous room using the class method
    if (_activeConversationId != null) {
      leaveConversation(_activeConversationId!);
    }

    // 2. Update active ID
    _activeConversationId = conversation.id;

    // 3. Join new room using the class method
    joinConversation(_activeConversationId!);

    state = state.copyWith(
      selectedConversation: conversation,
      messages: [],
      messagePage: 1,
      hasMoreMessages: false,
      sendError: null,
      typingUserId: null,
    );

    await _reloadMessages(conversation.id);
  }

  // â”€â”€ Add these as class methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void joinConversation(String conversationId) {
    _socket.emitWhenConnected('join_conversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket.socket?.emit('leave_conversation', conversationId);
  }

  Future<void> _reloadMessages(String conversationId, {int page = 1}) async {
    try {
      final result = await _repo.getMessages(conversationId, page: page);
      state = state.copyWith(
        messages: result.messages,
        hasMoreMessages: result.hasMore,
        messagePage: page,
      );
    } catch (e) {
      final msg = e is DioException
          ? (e.message ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(errorMessage: msg);
    }
  }

  Future<void> loadMoreMessages() async {
    final conv = state.selectedConversation;
    if (conv == null || !state.hasMoreMessages) return;
    try {
      final result = await _repo.getMessages(
        conv.id,
        page: state.messagePage + 1,
      );
      state = state.copyWith(
        messages: [...result.messages, ...state.messages],
        hasMoreMessages: result.hasMore,
        messagePage: state.messagePage + 1,
      );
    } catch (e) {
      final msg = e is DioException
          ? (e.message ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(errorMessage: msg);
    }
  }

  void clearSelectedConversation() {
    if (_activeConversationId != null) {
      _socket.leaveConversation(_activeConversationId!);
      _activeConversationId = null;
    }
    state = state.copyWith(
      selectedConversation: null,
      messages: [],
      hasMoreMessages: false,
      messagePage: 1,
      sendError: null,
      typingUserId: null,
    );
  }

  // â”€â”€ Send message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<bool> sendMessage(String content) async {
    final conv = state.selectedConversation;
    if (conv == null || content.trim().isEmpty) return false;

    state = state.copyWith(isSending: true, sendError: null);
    try {
      final message = await _repo.sendMessage(
        conversationId: conv.id,
        content: content.trim(),
      );

      final alreadyHasMessage = state.messages.any((m) => m.id == message.id);
      state = state.copyWith(
        isSending: false,
        messages: alreadyHasMessage
            ? state.messages
            : [...state.messages, message],
      );

      await loadConversations(silent: true);
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? e.message)
          : e.toString();
      state = state.copyWith(isSending: false, sendError: message);
      return false;
    }
  }

  //
  // Future<bool> sendMessage(String content) async {
  //   final conv = state.selectedConversation;
  //   if (conv == null || content.trim().isEmpty) return false;
  //
  //   state = state.copyWith(
  //     isSending: true,
  //     sendError: null,
  //   );
  //
  //   try {
  //     final message = await _repo.sendMessage(
  //       conversationId: conv.id,
  //       content: content.trim(),
  //     );
  //
  //     state = state.copyWith(
  //       isSending: false,
  //       messages: [...state.messages, message],
  //     );
  //
  //     await loadConversations(silent: true);
  //     return true;
  //   } catch (e) {
  //     state = state.copyWith(
  //       isSending: false,
  //       sendError: e.toString(),
  //     );
  //     return false;
  //   }
  // }

  // â”€â”€ Upload attachment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<bool> uploadAttachment({
    required String filePath,
    required String fileName,
    required String mimeType,
    String? caption,
  }) async {
    final conv = state.selectedConversation;
    if (conv == null) return false;

    state = state.copyWith(isUploading: true, sendError: null);
    try {
      await _repo.uploadAttachment(
        conversationId: conv.id,
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        caption: caption,
      );
      state = state.copyWith(
        isUploading: false,
        // messages: [...state.messages, message],
      );
      await loadConversations(silent: true);
      return true;
    } catch (e) {
      final msg = e is DioException
          ? (e.message ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isUploading: false, sendError: msg);
      return false;
    }
  }

  // â”€â”€ Delete / read â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> deleteMessage(String messageId) async {
    state = state.copyWith(deletingMessageId: messageId);
    try {
      await _repo.deleteMessage(messageId);
      state = state.copyWith(
        deletingMessageId: null,
        messages: state.messages
            .map(
              (m) => m.id == messageId
                  ? m.copyWith(
                      content: null,
                      attachmentUrl: null,
                      attachmentKey: null,
                      attachmentSignedUrl: null,
                    )
                  : m,
            )
            .toList(),
      );
    } catch (e) {
      final msg = e is DioException
          ? (e.message ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(deletingMessageId: null, errorMessage: msg);
    }
  }

  Future<void> markMessageRead(String messageId) async {
    try {
      await _repo.markMessageRead(messageId);
      state = state.copyWith(
        messages: state.messages
            .map((m) => m.id == messageId ? m.copyWith(status: 'READ') : m)
            .toList(),
      );
      final unread = await _repo.getUnreadCount();
      state = state.copyWith(unreadCount: unread);
    } catch (_) {
      // non-critical
    }
  }

  // â”€â”€ Typing indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void sendTyping() {
    final conv = state.selectedConversation;
    if (conv == null) return;
    _socket.emitTyping(conv.id);
  }

  // â”€â”€ User search â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> loadMessageableRecipients() async {
    state = state.copyWith(isSearchingUsers: true, errorMessage: null);

    try {
      final data = await _repo.getMessageableRecipients();

      final rawContacts = <Map<String, dynamic>>[];

      for (final key in ['recent', 'facilityStaff', 'nurses', 'support']) {
        rawContacts.addAll(
          List<Map<String, dynamic>>.from(data[key] ?? const []),
        );
      }

      final contacts = <UserSearchResult>[];
      final seen = <String>{};

      for (final raw in rawContacts) {
        final contact = UserSearchResult.fromJson(raw);

        if (contact.id.isNotEmpty && seen.add(contact.id)) {
          contacts.add(contact);
        }
      }

      state = state.copyWith(
        userSearchResults: contacts,
        isSearchingUsers: false,
      );
    } catch (e) {
      final message = e is DioException
          ? (e.response?.data?['message']?.toString() ??
                e.message ??
                'Unable to load contacts')
          : e.toString();

      state = state.copyWith(
        isSearchingUsers: false,
        userSearchResults: const [],
        errorMessage: message,
      );
    }
  }

  void selectRecipient(UserSearchResult user) {
    state = state.copyWith(selectedRecipient: user, userSearchResults: []);
  }

  void clearRecipient() {
    state = state.copyWith(selectedRecipient: null, userSearchResults: []);
  }

  Future<bool> startConversation() async {
    final recipient = state.selectedRecipient;
    if (recipient == null) return false;

    state = state.copyWith(isStartingConversation: true);
    try {
      final conversation = await _repo.startConversation(
        recipientId: recipient.id,
      );
      state = state.copyWith(
        isStartingConversation: false,
        selectedRecipient: null,
        userSearchResults: [],
      );
      await loadConversations(silent: true);
      await selectConversation(conversation);
      return true;
    } catch (e) {
      final msg = e is DioException
          ? (e.message ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(isStartingConversation: false, errorMessage: msg);
      return false;
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchDebounce?.cancel();
    _typingTimer?.cancel();
    if (_activeConversationId != null) {
      _socket.leaveConversation(_activeConversationId!);
    }
    super.dispose();
  }
}
