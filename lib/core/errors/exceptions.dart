class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Pas de réseau ou serveur injoignable -> on reste en mode hors-ligne.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Serveur injoignable']);
}

/// Le serveur a répondu avec une erreur (500, etc.).
class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode});
}

/// Ressource inexistante sur le serveur (404).
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Ressource introuvable']);
}

/// Identifiants invalides ou non autorisé.
class AuthException extends AppException {
  const AuthException([super.message = 'Non autorisé']);
}