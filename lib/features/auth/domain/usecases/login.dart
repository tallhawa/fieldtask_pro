import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class Login {
  final AuthRepository repository;
  Login(this.repository);

  Future<AuthSession> call(String email, String password) =>
      repository.login(email, password);
}