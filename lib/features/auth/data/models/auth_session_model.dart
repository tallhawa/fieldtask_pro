import '../../domain/entities/auth_session.dart';

class AuthSessionModel {
  final String userId;
  final String name;
  final String email;
  final String token;

  const AuthSessionModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.token,
  });

  /// Lit un utilisateur du serveur OU une session sauvegardée (même format).
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
    );
  }

  /// Format sauvegardé dans le stockage sécurisé (jamais le mot de passe).
  Map<String, dynamic> toJson() => {
        'id': userId,
        'name': name,
        'email': email,
        'token': token,
      };

  AuthSession toEntity() {
    return AuthSession(
      userId: userId,
      name: name,
      email: email,
      token: token,
    );
  }
}