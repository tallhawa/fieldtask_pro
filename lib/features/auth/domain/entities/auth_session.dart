import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String token;

  const AuthSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.token,
  });

  @override
  List<Object?> get props => [userId, email, token];
}