import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'messaging_api.dart';
import 'messaging_repository.dart';
import 'models/conversation_model.dart';
import 'models/message_model.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingApi _api;
  final AppCache _cache;

  MessagingRepositoryImpl(this._api, this._cache);

  @override
  Future<({List<ConversationModel> conversations, int total})>
  getConversations({int page = 1, int limit = 20}) async {
    final key = CacheKeys.conversations(page: page);
    final cached =
    _cache.get<({List<ConversationModel> conversations, int total})>(key);

    // Serve from cache and still refresh in background if stale
    if (cached != null && !cached.isExpired) {
      if (cached.isStale) _refreshConversationsInBackground(key, page, limit);
      return cached.data;
    }

    return _fetchAndCacheConversations(key, page, limit);
  }

  Future<({List<ConversationModel> conversations, int total})>
  _fetchAndCacheConversations(String key, int page, int limit) async {
    final raw = await _api.fetchConversations(page: page, limit: limit);
    final data = raw['data'] as List? ?? [];
    final pagination = raw['pagination'] as Map<String, dynamic>? ?? {};
    final result = (
    conversations: data.map((j) => ConversationModel.fromJson(j)).toList(),
    total: pagination['total'] as int? ?? 0,
    );
    _cache.set(key, result, CacheTtl.conversations);
    return result;
  }

  void _refreshConversationsInBackground(
      String key, int page, int limit) {
    // Fire-and-forget background refresh
    _fetchAndCacheConversations(key, page, limit).ignore();
  }

  @override
  Future<({List<MessageModel> messages, int total, bool hasMore})> getMessages(
      String conversationId, {
        int page = 1,
        int limit = 50,
      }) async {
    final key = CacheKeys.messages(conversationId, page: page);
    // Only cache page 1 — older pages are historical and don't change
    if (page == 1) {
      final cached =
      _cache.get<({List<MessageModel> messages, int total, bool hasMore})>(
          key);
      if (cached != null && !cached.isExpired) return cached.data;
    }

    final raw = await _api.fetchMessages(conversationId, page: page, limit: limit);
    final data = raw['data'] as List? ?? [];
    final pagination = raw['pagination'] as Map<String, dynamic>? ?? {};
    final result = (
    messages: data.map((j) => MessageModel.fromJson(j)).toList(),
    total: pagination['total'] as int? ?? 0,
    hasMore: pagination['hasNext'] as bool? ?? false,
    );
    _cache.set(key, result, CacheTtl.messages);
    return result;
  }

  @override
  Future<ConversationModel> startConversation({
    required String recipientId,
    String? facilityId,
  }) async {
    final raw = await _api.startConversation(
        recipientId: recipientId, facilityId: facilityId);
    _cache.invalidatePrefix(CacheKeys.prefixConversations);
    return ConversationModel.fromJson(raw['data']);
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final raw =
    await _api.sendMessage(conversationId: conversationId, content: content);
    // Bust message and conversation caches after send
    _cache.invalidate(CacheKeys.messages(conversationId));
    _cache.invalidatePrefix(CacheKeys.prefixConversations);
    return MessageModel.fromJson(raw['data']);
  }

  @override
  Future<MessageModel> uploadAttachment({
    required String conversationId,
    required String filePath,
    required String fileName,
    required String mimeType,
    String? caption,
  }) async {
    final raw = await _api.uploadAttachment(
      conversationId: conversationId,
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
      caption: caption,
    );
    _cache.invalidate(CacheKeys.messages(conversationId));
    _cache.invalidatePrefix(CacheKeys.prefixConversations);
    return MessageModel.fromJson(raw['data']);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _api.deleteMessage(messageId);
    // Can't know which conversation without extra state — bust all message caches
    _cache.invalidatePrefix(CacheKeys.prefixMessages);
  }

  @override
  Future<void> markMessageRead(String messageId) async {
    await _api.markMessageRead(messageId);
    _cache.invalidatePrefix(CacheKeys.prefixMessages);
    _cache.invalidatePrefix(CacheKeys.prefixConversations);
  }

  @override
  Future<int> getUnreadCount() async {
    final key = CacheKeys.unreadCount;
    final cached = _cache.get<int>(key);
    if (cached != null && !cached.isExpired) return cached.data;

    final raw = await _api.fetchUnreadCount();
    final count = raw['data']?['unreadCount'] as int? ?? 0;
    _cache.set(key, count, CacheTtl.unreadCount);
    return count;
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    // Search results are not cached — always fresh
    final raw = await _api.searchUsers(query);
    return List<Map<String, dynamic>>.from(raw['data'] ?? []);
  }
}