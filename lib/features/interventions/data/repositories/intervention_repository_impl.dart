import 'dart:convert';

import '../../../../core/constants/sync_status.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/intervention.dart';
import '../../domain/repositories/intervention_repository.dart';
import '../datasources/intervention_local_datasource.dart';
import '../datasources/sync_queue_local_datasource.dart';
import '../mappers/intervention_mapper.dart';
import '../models/intervention_model.dart';
import '../models/sync_queue_item.dart';
import '../sync/sync_engine.dart';

class InterventionRepositoryImpl implements InterventionRepository {
  InterventionRepositoryImpl({
    required this.local,
    required this.queue,
    required this.syncEngine,
  });

  final InterventionLocalDataSource local;
  final SyncQueueLocalDataSource queue;
  final SyncEngine syncEngine;

  // ------------------------------------------------------------- lecture

  @override
  Future<List<Intervention>> getInterventions() async {
    var models = await local.getAll();
    if (models.isEmpty) {
      // Premier lancement : on attend une synchro (sans effet si hors-ligne).
      await syncEngine.sync();
      models = await local.getAll();
    }
    return models.map(InterventionMapper.toEntity).toList();
  }

  @override
  Future<Intervention?> getById(String id) async {
    final model = await local.getById(id);
    return model == null ? null : InterventionMapper.toEntity(model);
  }

  // ------------------------------------------------------------ écriture

  @override
  Future<void> createIntervention(Intervention intervention) async {
    final entity = intervention.copyWith(updatedAt: DateTime.now().toUtc());
    final model = InterventionMapper.toModel(
      entity,
      syncStatus: SyncStatus.pending,
    );
    await local.insertOrReplace(model);
    await _enqueue(model, SyncAction.create);
  }

  @override
  Future<void> updateStatus(String id, InterventionStatus status) =>
      _modify(id, (m) => m.copyWith(status: status.name));

  @override
  Future<void> updateNotes(String id, String notes) =>
      _modify(id, (m) => m.copyWith(notes: notes));

  @override
  Future<void> addPhoto(String id, String photoPath) =>
      _modify(id, (m) => m.copyWith(photoPaths: [...m.photoPaths, photoPath]));

  @override
  Future<void> saveSignature(String id, String signaturePath) =>
      _modify(id, (m) => m.copyWith(signaturePath: signaturePath));

  @override
  Future<void> syncNow() => syncEngine.sync();

  // ------------------------------------------------------------ interne

  /// Schéma commun à toutes les modifications :
  /// SQLite (pending) -> file d'attente -> demande de synchro.
  Future<void> _modify(
    String id,
    InterventionModel Function(InterventionModel) change,
  ) async {
    final current = await local.getById(id);
    if (current == null) {
      throw const NotFoundException('Intervention introuvable en local');
    }
    final updated = change(current).copyWith(
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      syncStatus: SyncStatus.pending,
    );
    await local.update(updated);
    await _enqueue(updated, SyncAction.update);
  }

  Future<void> _enqueue(InterventionModel model, String action) async {
    await queue.enqueue(SyncQueueItem(
      interventionId: model.id,
      actionType: action,
      payload: jsonEncode(model.toJson()), // format du serveur
      createdAt: DateTime.now().toUtc().toIso8601String(),
    ));
    syncEngine.requestSync();
  }
}