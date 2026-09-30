import 'package:dio/dio.dart';
import 'package:fieldtask_pro/core/errors/exceptions.dart';
import 'package:fieldtask_pro/core/network/dio_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

DioException make(DioExceptionType type, {int? status}) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: request, statusCode: status),
  );
}

void main() {
  test('un délai dépassé devient NetworkException', () {
    expect(
      mapDioException(make(DioExceptionType.connectionTimeout)),
      isA<NetworkException>(),
    );
  });

  test('une connexion impossible devient NetworkException', () {
    expect(
      mapDioException(make(DioExceptionType.connectionError)),
      isA<NetworkException>(),
    );
  });

  test('HTTP 404 devient NotFoundException', () {
    expect(
      mapDioException(make(DioExceptionType.badResponse, status: 404)),
      isA<NotFoundException>(),
    );
  });

  test('HTTP 401 devient AuthException', () {
    expect(
      mapDioException(make(DioExceptionType.badResponse, status: 401)),
      isA<AuthException>(),
    );
  });

  test('HTTP 500 devient ServerException avec son code', () {
    final e = mapDioException(make(DioExceptionType.badResponse, status: 500));

    expect(e, isA<ServerException>());
    expect((e as ServerException).statusCode, 500);
  });
}