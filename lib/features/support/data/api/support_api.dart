import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/providers/auth_provider.dart';

class SupportApi {
  final Dio _dio;

  SupportApi(this._dio);

  // ... (same methods as before)
  Future<Map<String, dynamic>> getFaqs() => _dio.get('/support/faqs').then((r) => r.data);

  Future<Map<String, dynamic>> submitTicket(Map<String, dynamic> payload) =>
      _dio.post('/support', data: payload).then((r) => r.data);

  Future<Map<String, dynamic>> getTickets({
    int page = 1,
    int limit = 15,
    String? status,
    String? search,
  }) async {
    final params = {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    return _dio.get('/support', queryParameters: params).then((r) => r.data);
  }

  Future<Map<String, dynamic>> getTicketDetail(String ticketId) =>
      _dio.get('/support/$ticketId').then((r) => r.data);

  Future<void> addReply({
    required String ticketId,
    required String body,
    bool isInternal = false,
  }) async {
    await _dio.post('/support/$ticketId/replies', data: {
      'body': body,
      'isInternal': isInternal,
    });
  }
}

// ── Provider ─────────────────────────────────────
final supportApiProvider = Provider<SupportApi>((ref) {
  final dio = ref.watch(dioProvider); // Assuming you have a global dioProvider
  return SupportApi(dio);
});