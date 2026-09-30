import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.local});

  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  /// La connexion nécessite le réseau (vérification par le serveur).
  @override
  Future<AuthSession> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Email et mot de passe obligatoires');
    }
    final session = await remote.login(email.trim(), password);
    await local.saveSession(session);
    return session.toEntity();
  }

  /// Aucun appel réseau : le technicien peut rouvrir l'app en zone blanche.
  @override
  Future<AuthSession?> restoreSession() async {
    final session = await local.readSession();
    return session?.toEntity();
  }

  @override
  Future<void> logout() => local.clear();
}