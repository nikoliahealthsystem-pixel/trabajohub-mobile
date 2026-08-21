import 'models/conversation_model.dart';
import 'models/message_model.dart';

abstract class MessagingRepository {
  Future<({List<ConversationModel> conversations, int total})> getConversations({int page, int limit});
  Future<({List<MessageModel> messages, int total, bool hasMore})> getMessages(String conversationId, {int page, int limit});
  Future<ConversationModel> startConversation({required String recipientId, String? facilityId});
  Future<MessageModel> sendMessage({required String conversationId, required String content});
  Future<MessageModel> uploadAttachment({required String conversationId, required String filePath, required String fileName, required String mimeType, String? caption});
  Future<void> deleteMessage(String messageId);
  Future<void> markMessageRead(String messageId);
  Future<int> getUnreadCount();
  Future<List<Map<String, dynamic>>> searchUsers(String query);
}