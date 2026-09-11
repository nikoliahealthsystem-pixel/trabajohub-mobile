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

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<int> fetchUnreadCount() async {
    final response = await _client.instance.get('/notifications/unread-count');

    final raw = Map<String, dynamic>.from(response.data as Map);

    final data = Map<String, dynamic>.from(raw['data'] ?? const {});

    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> markOneRead(String id) async {
    await _client.instance.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.instance.patch('/notifications/read-all');
  }

  Future<Map<String, dynamic>> fetchPreferences() async {
    final response = await _client.instance.get('/notifications/preferences');

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updatePreferences(
    Map<String, bool> updates,
  ) async {
    final response = await _client.instance.patch(
      '/notifications/preferences',
      data: updates,
    );

    return Map<String, dynamic>.from(response.data as Map);
  }
}
