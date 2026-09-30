import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../models/auth_session_model.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSource(this._dio);

  /// JSON-Server n'a pas de vrai /login : on cherche l'utilisateur
  /// par email + mot de passe et on renvoie son token simulé.
  Future<AuthSessionModel> login(String email, String password) async {
    try {
      final res = await _dio.get(
        '/users',
        queryParameters: {'email': email, 'password': password},
      );
      final users = res.data as List;
      if (users.isEmpty) {
        throw const AuthException('Email ou mot de passe incorrect');
      }
      return AuthSessionModel.fromJson(users.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}