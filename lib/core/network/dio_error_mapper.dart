import 'dart:io';

import 'package:dio/dio.dart';

import '../errors/exceptions.dart';

AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();

    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      if (code == 404) return const NotFoundException();
      if (code == 401 || code == 403) return const AuthException();
      return ServerException('Erreur serveur ($code)', statusCode: code);

    default:
      if (e.error is SocketException) return const NetworkException();
      return ServerException(e.message ?? 'Erreur inconnue');
  }
}