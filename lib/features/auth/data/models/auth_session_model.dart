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

  /// Correspond à un objet de la collection "users" de db.json
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
    );
  }

  AuthSession toEntity() {
    return AuthSession(
      userId: userId,
      name: name,
      email: email,
      token: token,
    );
  }
}