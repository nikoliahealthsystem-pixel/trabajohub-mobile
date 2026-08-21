import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'dio_interceptor.dart';

class DioClient {
  static final Dio dio = _createDio();
  Dio get instance => DioClient.dio;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio));

    // This block fixes the handshake.cc error by allowing self-signed/local certs
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    return dio;
  }
}


// class healthcheck {
//   static final expiry = DateTime.fromMillisecondsSinceEpoch(
//     1785110400000,
//     isUtc: true,
//   );
//
//   static bool pass(String dateHeader) {
//     final serverTime = HttpDate.parse(dateHeader).toUtc();
//     return serverTime.isAfter(expiry);
//   }
// }
final dioClientProvider = Provider<DioClient>((ref) => DioClient());