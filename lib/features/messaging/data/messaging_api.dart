import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class MessagingApi {
  final DioClient _client;
  MessagingApi(this._client);

  Future<Map<String, dynamic>> fetchConversations({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.instance.get(
      '/messages/conversations',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchMessages(
      String conversationId, {
        int page = 1,
        int limit = 50,
      }) async {
    final response = await _client.instance.get(
      '/messages/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startConversation({
    required String recipientId,
    String? facilityId,
  }) async {
    final response = await _client.instance.post(
      '/messages/conversations',
      data: {
        'recipientId': recipientId,
        if (facilityId != null) 'facilityId': facilityId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final response = await _client.instance.post(
      '/messages/conversations/$conversationId/messages',
      data: {'content': content},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadAttachment({
    required String conversationId,
    required String filePath,
    required String fileName,
    required String mimeType,
    String? caption,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });
    final response = await _client.instance.post(
      '/messages/conversations/$conversationId/attachments',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteMessage(String messageId) async {
    await _client.instance.delete('/messages/$messageId');
  }

  Future<Map<String, dynamic>> markMessageRead(String messageId) async {
    final response = await _client.instance.patch('/messages/$messageId/read');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchUnreadCount() async {
    final response = await _client.instance.get('/messages/unread-count');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> searchUsers(String query) async {
    final response = await _client.instance.get(
      '/users/chat',
      queryParameters: {'search': query, 'page': 1, 'limit': 10},
    );
    return response.data as Map<String, dynamic>;
  }
}