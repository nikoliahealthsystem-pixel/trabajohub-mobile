import '../../../core/network/dio_client.dart';

class NotificationsApi {
  final DioClient _client;
  NotificationsApi(this._client);

  Future<Map<String, dynamic>> fetchNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _client.instance.get(
      '/notifications',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (unreadOnly) 'unreadOnly': 'true',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> markOneRead(String id) async {
    await _client.instance.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.instance.patch('/notifications/read-all');
  }
}