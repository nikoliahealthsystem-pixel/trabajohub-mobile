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
    required String verificationMethod,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? qrCode,
    String? pin,
    String? reason,
  }) async {
    final response = await _client.instance.post(
      '/visits/$visitId/check-in',
      data: {
        'verificationMethod': verificationMethod,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (qrCode != null && qrCode.isNotEmpty) 'qrCode': qrCode,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkOut({
    required String visitId,
    required String verificationMethod,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? qrCode,
    String? pin,
    String? reason,
    String? notes,
  }) async {
    final response = await _client.instance.post(
      '/visits/$visitId/check-out',
      data: {
        'verificationMethod': verificationMethod,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (qrCode != null && qrCode.isNotEmpty) 'qrCode': qrCode,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    return response.data as Map<String, dynamic>;
  }
}
