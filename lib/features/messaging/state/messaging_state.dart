import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';

const _sentinel = Object();

enum MessagingStatus { initial, loading, loadingMore,success, error }
enum MessageFetchStatus { idle, loading, loadingMore, success, error }

class UserSearchResult {
  final String id;
  final String email;
  final String role;
  final String displayName;
  final String subtitle;

  const UserSearchResult({
    required this.id,
    required this.email,
    required this.role,
    required this.displayName,
    required this.subtitle,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    String display = json['email'];
    String sub = json['role'] ?? '';

    final admin = json['adminProfile'] as Map<String, dynamic>?;
    final nurse = json['nurseProfile'] as Map<String, dynamic>?;
    final member = json['facilityMember'] as Map<String, dynamic>?;

    if (admin != null) display = '${admin['firstName']} ${admin['lastName']}';
    if (nurse != null) {
      display = '${nurse['firstName']} ${nurse['lastName']}';
      if (nurse['designation'] != null) sub = '$sub · ${nurse['designation']}';
    }
    if (member != null && admin == null && nurse == null) {
      display = '${member['firstName']} ${member['lastName']}';
    }

    return UserSearchResult(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      displayName: display,
      subtitle: sub,
    );
  }
}

class MessagingState {
  final MessagingStatus status;
  final List<ConversationModel> conversations;
  final ConversationModel? selectedConversation;
  final List<MessageModel> messages;
  final bool hasMoreMessages;
  final int messagePage;
  final int unreadCount;
  final bool isSending;
  final bool isUploading;
  final String? sendError;
  final List<UserSearchResult> userSearchResults;
  final bool isSearchingUsers;
  final UserSearchResult? selectedRecipient;
  final bool isStartingConversation;
  final String? deletingMessageId;
  final String? errorMessage;

  // ── Typing indicator ─────────────────────────────────────
  final String? typingUserId;
  final String? typingConversationId;

  const MessagingState({
    this.status = MessagingStatus.initial,
    this.conversations = const [],
    this.selectedConversation,
    this.messages = const [],
    this.hasMoreMessages = false,
    this.messagePage = 1,
    this.unreadCount = 0,
    this.isSending = false,
    this.isUploading = false,
    this.sendError,
    this.userSearchResults = const [],
    this.isSearchingUsers = false,
    this.selectedRecipient,
    this.isStartingConversation = false,
    this.deletingMessageId,
    this.errorMessage,
    this.typingUserId,
    this.typingConversationId,
  });

  MessagingState copyWith({
    MessagingStatus? status,
    List<ConversationModel>? conversations,
    Object? selectedConversation = _sentinel,
    List<MessageModel>? messages,
    bool? hasMoreMessages,
    int? messagePage,
    int? unreadCount,
    bool? isSending,
    bool? isUploading,
    Object? sendError = _sentinel,
    List<UserSearchResult>? userSearchResults,
    bool? isSearchingUsers,
    Object? selectedRecipient = _sentinel,
    bool? isStartingConversation,
    Object? deletingMessageId = _sentinel,
    Object? errorMessage = _sentinel,
    Object? typingUserId = _sentinel,
    Object? typingConversationId = _sentinel,
  }) =>
      MessagingState(
        status: status ?? this.status,
        conversations: conversations ?? this.conversations,
        selectedConversation: selectedConversation == _sentinel
            ? this.selectedConversation
            : selectedConversation as ConversationModel?,
        messages: messages ?? this.messages,
        hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
        messagePage: messagePage ?? this.messagePage,
        unreadCount: unreadCount ?? this.unreadCount,
        isSending: isSending ?? this.isSending,
        isUploading: isUploading ?? this.isUploading,
        sendError: sendError == _sentinel ? this.sendError : sendError as String?,
        userSearchResults: userSearchResults ?? this.userSearchResults,
        isSearchingUsers: isSearchingUsers ?? this.isSearchingUsers,
        selectedRecipient: selectedRecipient == _sentinel
            ? this.selectedRecipient
            : selectedRecipient as UserSearchResult?,
        isStartingConversation:
        isStartingConversation ?? this.isStartingConversation,
        deletingMessageId: deletingMessageId == _sentinel
            ? this.deletingMessageId
            : deletingMessageId as String?,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
        typingUserId: typingUserId == _sentinel
            ? this.typingUserId
            : typingUserId as String?,
        typingConversationId: typingConversationId == _sentinel
            ? this.typingConversationId
            : typingConversationId as String?,
      );
}