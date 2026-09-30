import 'dart:convert';

import 'package:fieldtask_pro/core/constants/sync_status.dart';
import 'package:fieldtask_pro/core/database/app_database.dart';
import 'package:fieldtask_pro/core/errors/exceptions.dart';
import 'package:fieldtask_pro/features/interventions/data/datasources/intervention_local_datasource.dart';
import 'package:fieldtask_pro/features/interventions/data/datasources/sync_queue_local_datasource.dart';
import 'package:fieldtask_pro/features/interventions/data/models/intervention_model.dart';
import 'package:fieldtask_pro/features/interventions/data/models/sync_queue_item.dart';
import 'package:fieldtask_pro/features/interventions/data/repositories/intervention_repository_impl.dart';
import 'package:fieldtask_pro/features/interventions/data/sync/sync_engine.dart';
import 'package:fieldtask_pro/features/interventions/domain/entities/intervention.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockSyncEngine extends Mock implements SyncEngine {}

InterventionModel sampleModel() {
  return const InterventionModel(
    id: 'i1',
    title: 'Titre',
    clientName: 'Client',
    address: 'Adresse',
    description: 'Desc',
    equipment: 'Equip',
    status: 'pending',
    priority: 'high',
    latitude: 14.69,
    longitude: -17.44,
    scheduledAt: '2026-10-01T09:00:00.000Z',
    updatedAt: '2020-01-01T00:00:00.000Z',
  );
}

Intervention newEntity() {
  return Intervention(
    id: 'new-1',
    title: 'Créée hors-ligne',
    clientName: 'Client',
    address: 'Dakar',
    description: 'Desc',
    equipment: 'Routeur',
    status: InterventionStatus.pending,
    priority: InterventionPriority.low,
    latitude: 14.69,
    longitude: -17.44,
    scheduledAt: DateTime.utc(2026, 10, 5, 9),
    updatedAt: DateTime.utc(2020, 1, 1),
  );
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late InterventionLocalDataSource local;
  late SyncQueueLocalDataSource queue;
  late MockSyncEngine engine;
  late InterventionRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(path: inMemoryDatabasePath);
    local = InterventionLocalDataSource(db);
    queue = SyncQueueLocalDataSource(db);
    engine = MockSyncEngine();
    when(() => engine.sync()).thenAnswer((_) async {});
    // requestSync() est void : un mock non configuré renvoie simplement null.
    repo = InterventionRepositoryImpl(
      local: local,
      queue: queue,
      syncEngine: engine,
    );
  });

  tearDown(() async => db.close());

  test('updateStatus : SQLite passe en pending et une action est empilée',
      () async {
    await local.insertOrReplace(sampleModel());

    await repo.updateStatus('i1', InterventionStatus.inProgress);

    final row = await local.getById('i1');
    expect(row?.status, 'inProgress');
    expect(row?.syncStatus, SyncStatus.pending);
    expect(
      DateTime.parse(row!.updatedAt).isAfter(DateTime.utc(2020, 1, 1)),
      isTrue,
    );

    final items = await queue.getAll();
    expect(items, hasLength(1));
    expect(items.first.actionType, SyncAction.update);
    expect((jsonDecode(items.first.payload) as Map)['status'], 'inProgress');
    verify(() => engine.requestSync()).called(1);
  });

  test('createIntervention : ligne pending et action « create »', () async {
    await repo.createIntervention(newEntity());

    final row = await local.getById('new-1');
    expect(row?.syncStatus, SyncStatus.pending);

    final items = await queue.getAll();
    expect(items.single.actionType, SyncAction.create);
    expect(items.single.interventionId, 'new-1');
    verify(() => engine.requestSync()).called(1);
  });

  test('deux modifications donnent deux actions dans l\'ordre (FIFO)',
      () async {
    await local.insertOrReplace(sampleModel());

    await repo.updateNotes('i1', 'Câble remplacé');
    await repo.updateStatus('i1', InterventionStatus.done);

    final items = await queue.getAll();
    expect(items, hasLength(2));
    final last = jsonDecode(items.last.payload) as Map;
    expect(last['status'], 'done');
    expect(last['notes'], 'Câble remplacé'); // l'état complet est envoyé
  });

  test('addPhoto conserve les photos dans l\'ordre de prise', () async {
    await local.insertOrReplace(sampleModel());

    await repo.addPhoto('i1', 'a.jpg');
    await repo.addPhoto('i1', 'b.jpg');

    final entity = await repo.getById('i1');
    expect(entity?.photoPaths, ['a.jpg', 'b.jpg']);
  });

  test('modifier une intervention inconnue lève NotFoundException', () async {
    await expectLater(
      repo.updateNotes('inconnue', 'x'),
      throwsA(isA<NotFoundException>()),
    );
    expect(await queue.count(), 0);
  });

  test('getInterventions ne lance une synchro que si la base locale est vide',
      () async {
    await repo.getInterventions();
    verify(() => engine.sync()).called(1);

    await local.insertOrReplace(sampleModel());
    clearInteractions(engine);

    final list = await repo.getInterventions();
    verifyNever(() => engine.sync());
    expect(list, hasLength(1));
  });

  test('getById renvoie null pour une intervention inconnue', () async {
    expect(await repo.getById('zzz'), isNull);
  });
}