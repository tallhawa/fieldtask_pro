import 'package:dio/dio.dart';

import '../constants/api_config.dart';

typedef TokenProvider = Future<String?> Function();

/// Crée le client HTTP de l'application.
/// [tokenProvider] sera branché sur flutter_secure_storage en phase 5.
Dio createDio({TokenProvider? tokenProvider, String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
}