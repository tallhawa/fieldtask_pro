import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RestoreSession {
  final AuthRepository repository;
  RestoreSession(this.repository);

  /// Renvoie la session sauvegardée, ou null si l'utilisateur doit se reconnecter.
  Future<AuthSession?> call() => repository.restoreSession();
}