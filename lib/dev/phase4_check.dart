import 'package:flutter/foundation.dart';

import '../core/database/app_database.dart';
import '../core/di/app_dependencies.dart';
import '../core/network/dio_client.dart';
import '../features/interventions/data/datasources/intervention_local_datasource.dart';
import '../features/interventions/data/datasources/sync_queue_local_datasource.dart';
import '../features/interventions/domain/entities/intervention.dart';

const _deadServer = 'http://10.0.2.2:3999'; // simule « serveur injoignable »

Future<void> runPhase4Check() async {
  final db = AppDatabase();
  final localDs = InterventionLocalDataSource(db);
  await localDs.deleteAll();
  await SyncQueueLocalDataSource(db).clear();

  final raw = createDio(); // accès direct au serveur pour vérifier
  final original =
      (await raw.get('/interventions/i1')).data as Map<String, dynamic>;

  // 1. Premier lancement, en ligne : téléchargement de la liste
  var app = await AppDependencies.create(database: db);
  final list = await app.getInterventions();
  debugPrint('[P4] 1. Premier chargement : ${list.length} intervention(s) (attendu : 3 ou plus)');
  await app.dispose();

  // 2. Serveur coupé : 2 modifications + 1 création
  app = await AppDependencies.create(database: db, baseUrl: _deadServer);
  await app.updateStatus('i1', InterventionStatus.inProgress);
  await app.addNote('i1', 'Note prise hors-ligne');
  await app.createIntervention(Intervention(
    id: 'p4-test',
    title: 'Créée hors-ligne',
    clientName: 'Client Test',
    address: 'Dakar',
    description: 'Créée par phase4_check',
    equipment: 'Routeur',
    status: InterventionStatus.pending,
    priority: InterventionPriority.low,
    latitude: 14.69,
    longitude: -17.44,
    scheduledAt: DateTime.utc(2026, 10, 5, 9),
    updatedAt: DateTime.now().toUtc(),
  ));
  await app.syncEngine.sync(); // échoue : serveur injoignable
  final i1 = await app.getInterventionById('i1');
  debugPrint('[P4] 2. Hors-ligne : i1 local = ${i1?.status.name} | notes="${i1?.notes}" | file = ${app.syncEngine.state.pendingCount} (attendu : inProgress, "Note prise hors-ligne", 3)');
  debugPrint('[P4]    en ligne ? ${app.syncEngine.state.isOnline} (attendu : false) | erreur : ${app.syncEngine.state.lastError}');

  // 3. Le serveur n'a rien reçu
  final before = (await raw.get('/interventions/i1')).data as Map<String, dynamic>;
  debugPrint('[P4] 3. Serveur i1 = ${before['status']} (attendu : ${original['status']}, inchangé)');
  await app.dispose();

  // 4. Retour en ligne : la file se vide toute seule
  app = await AppDependencies.create(database: db);
  await app.syncNow();
  final srv = (await raw.get('/interventions/i1')).data as Map<String, dynamic>;
  final created = (await raw.get('/interventions/p4-test')).data as Map<String, dynamic>;
  final row = await localDs.getById('i1');
  debugPrint('[P4] 4. Retour en ligne : file = ${app.syncEngine.state.pendingCount} (attendu : 0)');
  debugPrint('[P4]    serveur i1 = ${srv['status']} / "${srv['notes']}" (attendu : inProgress / "Note prise hors-ligne")');
  debugPrint('[P4]    serveur p4-test = "${created['title']}" | local sync_status = ${row?.syncStatus} (attendu : synced)');
  await app.dispose();

  // 5. Conflit : le serveur a une version plus récente -> elle gagne
  await raw.put('/interventions/i1', data: {
    ...original,
    'notes': 'Version serveur',
    'updatedAt': '2099-01-01T00:00:00.000Z',
  });
  app = await AppDependencies.create(database: db, baseUrl: _deadServer);
  await app.addNote('i1', 'Version locale');
  await app.dispose();
  app = await AppDependencies.create(database: db);
  await app.syncNow();
  final after = await app.getInterventionById('i1');
  debugPrint('[P4] 5. Conflit : notes = "${after?.notes}" (attendu : Version serveur)');

  // 6. Nettoyage du serveur
  await raw.put('/interventions/i1', data: original);
  await raw.delete('/interventions/p4-test');
  await app.dispose();

  debugPrint('[P4] === PHASE 4 TERMINÉE ===');
}