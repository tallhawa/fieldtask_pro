import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/di/app_dependencies.dart';
import '../core/errors/exceptions.dart';
import '../core/network/dio_client.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/models/auth_session_model.dart';

const _deadServer = 'http://10.0.2.2:3999'; // simule « serveur injoignable »

// await runPhase5Check();   (le bloc try/catch complet)

Future<void> runPhase5Check() async {
  final authStore = AuthLocalDataSource();
  await authStore.clear();

  var app = await AppDependencies.create();

  // 1. Premier lancement : pas de session
  debugPrint('[P5] 1. Session au premier lancement : ${await app.restoreSession()} (attendu : null)');

  // 2. Mauvais mot de passe
  try {
    await app.signIn('tech@techfix.sn', 'mauvais');
    debugPrint('[P5] 2. ERREUR : la connexion aurait dû échouer');
  } on AuthException catch (e) {
    debugPrint('[P5] 2. Mauvais mot de passe refusé : $e');
  }

  // 3. Le serveur refuse les requêtes sans token
  try {
    await createDio().get('/interventions');
    debugPrint('[P5] 3. ERREUR : le serveur aurait dû répondre 401');
  } on DioException catch (e) {
    debugPrint('[P5] 3. Sans token : HTTP ${e.response?.statusCode} (attendu : 401)');
  }

  // 4. Connexion réussie + session sauvegardée
  final session = await app.signIn('tech@techfix.sn', '1234');
  final restored = await app.restoreSession();
  debugPrint('[P5] 4. Connecté : ${session.name} | session relue : ${restored?.token == session.token} (attendu : true)');
  await app.dispose();

  // 5. Redémarrage SANS réseau : la session est restaurée quand même
  app = await AppDependencies.create(baseUrl: _deadServer);
  final offline = await app.restoreSession();
  debugPrint('[P5] 5. Redémarrage hors-ligne : session = ${offline?.email} (attendu : tech@techfix.sn)');
  await app.dispose();

  // 6. Avec le token, la synchro fonctionne
  app = await AppDependencies.create();
  await app.syncNow();
  final st = app.syncEngine.state;
  debugPrint('[P5] 6. Synchro avec token : erreur = ${st.lastError} | terminée = ${st.lastSyncAt != null} (attendu : null, true)');

  // 7. Token refusé par le serveur : la session est effacée et signalée
  await authStore.saveSession(const AuthSessionModel(
    userId: 'u1',
    name: 'Technicien Test',
    email: 'tech@techfix.sn',
    token: 'token-perime',
  ));
  var expired = false;
  final sub = app.sessionExpired.listen((_) => expired = true);
  await app.syncNow();
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await sub.cancel();
  debugPrint('[P5] 7. Token refusé : expiration signalée = $expired (attendu : true) | session restante = ${await app.restoreSession()} (attendu : null)');

  // 8. Déconnexion propre
  await app.signIn('tech@techfix.sn', '1234');
  final purged = await app.signOut();
  final afterLogout = await app.restoreSession();
  final leftovers = (await app.getInterventions()).length;
  debugPrint('[P5] 8. Déconnexion : données locales supprimées = $purged (attendu : true) | session = $afterLogout (attendu : null) | interventions locales = $leftovers (attendu : 0)');

  // 9. On laisse une session ouverte pour le test de redémarrage réel
  await app.signIn('tech@techfix.sn', '1234');
  await app.dispose();

  debugPrint('[P5] === PHASE 5 TERMINÉE ===');
}