import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/network/dio_client.dart';
import 'models/shift_model.dart';
import 'models/shift_assignment_model.dart';

class ShiftsApi {
  final DioClient _client;
  ShiftsApi(this._client);

  Future<Map<String, dynamic>> fetchMarketplace({
    int page = 1,
    int limit = 20,
    String? visitType,
    bool? isUrgent,
    double? minPay,
    double? maxPay,
    String? date,
    String? searchQuery,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (visitType != null) 'visitType': visitType,
      if (isUrgent == true) 'isUrgent': 'true',
      if (minPay != null) 'minPay': minPay,
      if (maxPay != null) 'maxPay': maxPay,
      if (date != null) 'date': date,
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
    };

    final response = await _client.instance.get(
      '/shifts/marketplace',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchMyShifts({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final response = await _client.instance.get(
      '/shifts/nurse/my-shifts',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchShiftById(String id) async {
    final response = await _client.instance.get('/shifts/$id');
    debugPrint(response.data.toString());
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bookShift(String shiftId) async {
    final response = await _client.instance.post('/shifts/$shiftId/book');
    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelShift(String shiftId, {String? reason}) async {
    await _client.instance.patch(
      '/shifts/$shiftId/cancel',
      data: {'reason': reason},
    );
  }
}