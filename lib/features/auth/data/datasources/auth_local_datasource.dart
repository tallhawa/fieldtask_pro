import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session_model.dart';

class AuthLocalDataSource {
  AuthLocalDataSource([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'auth_session';

  Future<void> saveSession(AuthSessionModel session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  Future<AuthSessionModel?> readSession() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return AuthSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Données illisibles (clé Keystore perdue après réinstallation, format
      // ancien...) : on repart proprement sur une session vide.
      try {
        await clear();
      } catch (_) {}
      return null;
    }
  }

  Future<String?> readToken() async => (await readSession())?.token;

  Future<bool> hasSession() async => (await readSession()) != null;

  Future<void> clear() => _storage.delete(key: _key);
}