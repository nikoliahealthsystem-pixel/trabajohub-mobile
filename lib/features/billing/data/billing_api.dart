import '../../../core/network/dio_client.dart';

class BillingApi {
  final DioClient _client;
  BillingApi(this._client);

  Future<Map<String, dynamic>> fetchWallet() async {
    final response = await _client.instance.get('/billing/wallet');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchPayouts({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final response = await _client.instance.get(
      '/billing/payouts',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}