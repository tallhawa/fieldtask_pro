import 'package:dio/dio.dart';

import '../constants/api_config.dart';

typedef TokenProvider = Future<String?> Function();

/// Crée le client HTTP de l'application.
/// - [tokenProvider] : fournit le token ajouté à chaque requête.
/// - [onUnauthorized] : appelé quand le serveur répond 401 (token refusé).
Dio createDio({
  TokenProvider? tokenProvider,
  void Function()? onUnauthorized,
  String? baseUrl,
}) {
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
      onError: (error, handler) {
        final isLoginCall = error.requestOptions.path.startsWith('/users');
        if (error.response?.statusCode == 401 && !isLoginCall) {
          onUnauthorized?.call();
        }
        handler.next(error); // l'erreur continue vers mapDioException
      },
    ),
  );

  return dio;
}