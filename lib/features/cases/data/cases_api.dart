import '../../../core/network/dio_client.dart';

class CasesApi {
  final DioClient _client;
  CasesApi(this._client);

  Future<Map<String, dynamic>> fetchCases({
    int page = 1,
    int limit = 20,
    String? visitType,
    bool? isActive,
    String? search,
  }) async {
    final response = await _client.instance.get(
      '/cases',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (visitType != null) 'visitType': visitType,
        if (isActive != null) 'isActive': isActive.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchCase(String id) async {
    final response = await _client.instance.get('/cases/$id');
    return response.data as Map<String, dynamic>;
  }
}