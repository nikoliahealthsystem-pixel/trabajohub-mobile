import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class CredentialsApi {
  final DioClient _client;
  CredentialsApi(this._client);

  Future<Map<String, dynamic>> fetchMine() async {
    final response = await _client.instance.get('/credentials/mine');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchOne(String id) async {
    final response = await _client.instance.get('/credentials/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadCredential({
    required String filePath,
    required String fileName,
    required String type,
    String? customLabel,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
      'type': type,
      if (customLabel != null && customLabel.isNotEmpty)
        'customLabel': customLabel,
      if (issuedAt != null)
        'issuedAt': issuedAt.toIso8601String(),
      if (expiresAt != null)
        'expiresAt': expiresAt.toIso8601String(),
    });

    final response = await _client.instance.post(
      '/credentials',
      data: formData,
    );

    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteCredential(String id) async {
    await _client.instance.delete('/credentials/$id');
  }
}