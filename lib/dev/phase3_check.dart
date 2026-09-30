import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/exceptions.dart';
import '../core/network/dio_client.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/interventions/data/datasources/intervention_remote_datasource.dart';
import '../features/interventions/data/models/intervention_model.dart';

Future<void> runPhase3Check() async {
  final dio = createDio();
  final remote = InterventionRemoteDataSource(dio);
  final auth = AuthRemoteDataSource(dio);

  // 1. Lecture de la liste
  final all = await remote.fetchAll();
  debugPrint('[P3] 1. fetchAll : ${all.length} intervention(s) (attendu : 3 ou plus)');
  debugPrint('[P3]    première : ${all.first.title} | statut=${all.first.status}');

  // 2. Connexion correcte
  final session = await auth.login('tech@techfix.sn', '1234');
  debugPrint('[P3] 2. login OK : ${session.name} | token=${session.token}');

  // 3. Connexion incorrecte
  try {
    await auth.login('tech@techfix.sn', 'mauvais');
    debugPrint('[P3] 3. ERREUR : le login aurait dû échouer');
  } on AuthException catch (e) {
    debugPrint('[P3] 3. login refusé comme prévu : $e');
  }

  // 4. Modification d'une intervention existante (PUT)
  final original = all.first;
  await remote.push(original.copyWith(notes: 'Test phase 3'));
  final updated = await remote.fetchById(original.id);
  debugPrint('[P3] 4. PUT : notes="${updated.notes}" (attendu : Test phase 3)');
  await remote.push(original); // remise en état d'origine

  // 5. Création d'une nouvelle intervention (PUT échoue en 404 -> POST)
  const fresh = InterventionModel(
    id: 'p3-test',
    title: 'Intervention créée hors-ligne',
    clientName: 'Client Test',
    address: 'Dakar',
    description: 'Créée par phase3_check',
    equipment: 'Routeur',
    status: 'pending',
    priority: 'low',
    latitude: 14.69,
    longitude: -17.44,
    scheduledAt: '2026-10-05T09:00:00.000Z',
    updatedAt: '2026-09-30T08:00:00.000Z',
  );
  await remote.push(fresh);
  final created = await remote.fetchById('p3-test');
  debugPrint('[P3] 5. POST : ${created.title}');

  // 6. Rejouer la même action ne crée pas de doublon
  await remote.push(fresh);
  final count = (await remote.fetchAll()).where((i) => i.id == 'p3-test').length;
  debugPrint('[P3] 6. Après 2 envois : $count exemplaire (attendu : 1)');
  await dio.delete('/interventions/p3-test'); // nettoyage

  // 7. Serveur injoignable (mauvais port)
  final deadRemote = InterventionRemoteDataSource(
    createDio(baseUrl: 'http://10.0.2.2:3999'),
  );
  try {
    await deadRemote.fetchAll();
    debugPrint('[P3] 7. ERREUR : une exception était attendue');
  } on NetworkException catch (e) {
    debugPrint('[P3] 7. hors-ligne détecté : $e');
  } on DioException catch (e) {
    debugPrint('[P3] 7. ERREUR : exception Dio non mappée : ${e.type}');
  }

  debugPrint('[P3] === PHASE 3 TERMINÉE ===');
}