import '../../../core/network/dio_client.dart';

class CalendarApi {
  final DioClient _client;
  CalendarApi(this._client);

  Future<Map<String, dynamic>> fetchEvents({
    required String from,
    required String to,
    List<String>? types,
    String? facilityId,
    String? nurseProfileId,
  }) async {
    final response = await _client.instance.get(
      '/calendar/events',
      queryParameters: {
        'from': from,
        'to': to,
        if (types != null && types.isNotEmpty) 'types': types.join(','),
        if (facilityId != null) 'facilityId': facilityId,
        if (nurseProfileId != null) 'nurseProfileId': nurseProfileId,
        'groupBy': 'none',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchUpcoming({int limit = 10}) async {
    final response = await _client.instance.get(
      '/calendar/upcoming',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }
}