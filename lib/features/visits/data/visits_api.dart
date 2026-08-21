import '../../../core/network/dio_client.dart';

class VisitsApi {
  final DioClient _client;
  VisitsApi(this._client);

  Future<Map<String, dynamic>> fetchVisits({
    int page = 1,
    int limit = 20,
    String? status,
    bool flaggedOnly = false,
  }) async {
    final response = await _client.instance.get(
      '/visits',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (flaggedOnly) 'flaggedOnly': 'true',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchVisit(String id) async {
    final response = await _client.instance.get('/visits/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkIn({
    required String visitId,
    required double latitude,
    required double longitude,
    String? qrCode,
  }) async {
    final response = await _client.instance.post(
      '/visits/$visitId/check-in',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (qrCode != null) 'qrCode': qrCode,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkOut({
    required String visitId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    final response = await _client.instance.post(
      '/visits/$visitId/check-out',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}