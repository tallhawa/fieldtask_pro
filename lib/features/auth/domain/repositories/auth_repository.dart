import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login(String email, String password);
  Future<AuthSession?> restoreSession();
  Future<void> logout();
}