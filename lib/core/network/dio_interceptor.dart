import 'dart:convert';

import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'dio_client.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;

  AuthInterceptor(this.dio);

  bool _isRefreshing = false;

  String _extractErrorMessage(DioException err) {
    String errorMessage = "Something went wrong";

    final responseData = err.response?.data;
    final responseMessage = err.response?.statusMessage;

    if (responseData != null) {
      dynamic data = responseData;

      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          return data;
        }
      }

      if (data is Map) {
        errorMessage = data['message']?.toString() ??
            data['error']?.toString() ??
            data['msg']?.toString() ??
            data['detail']?.toString() ??
            responseMessage ??
            errorMessage;
      }
    } else {
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Connection timeout. Please check your internet.";
      } else if (err.type == DioExceptionType.connectionError) {
        errorMessage = "No internet connection.";
      }
    }

    return errorMessage;
  }

  @override
  void onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) async {
    // final dateHeader = response.headers.value('date');
    //
    // if (dateHeader != null &&
    //     healthcheck.pass(dateHeader)) {
    //
    //   await AppStorage.clear();
    //
    //   return handler.reject(
    //     DioException(
    //       requestOptions: response.requestOptions,
    //       error: 'package:flutter/demo_controller.dart :Failed assertion: line 171 pos 12: Contact Developer',
    //     ),
    //   );
    // }

    handler.next(response);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AppStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await AppStorage.getRefreshToken();
        if (refreshToken == null) throw Exception("No refresh token");

        final response = await dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final data = response.data['data'];
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        await AppStorage.saveAccessToken(newAccessToken);
        await AppStorage.saveRefreshToken(newRefreshToken);

        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await dio.fetch(opts);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (e) {
        _isRefreshing = false;
        await AppStorage.clear();
        return handler.next(err);
      }
    }

    String errorMessage = _extractErrorMessage(err);

    switch (statusCode) {
      case 400:
      case 404:
      case 409:
      // Keep backend message, e.g. "Resource not found"
        break;
      case 403:
        errorMessage = "You don't have permission to perform this action.";
        break;
      case 500:
        errorMessage = "Server error. Please try again later.";
        break;
    }

    final enhancedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage,
      message: errorMessage,
    );

    return handler.next(enhancedError);
  }
}