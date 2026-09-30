import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/sync_status.dart';
import '../../../../core/database/app_database.dart';
import '../models/intervention_model.dart';

class InterventionLocalDataSource {
  final AppDatabase _appDb;
  InterventionLocalDataSource(this._appDb);

  static const _table = AppDatabase.tableInterventions;

  Future<List<InterventionModel>> getAll() async {
    final db = await _appDb.database;
    final rows = await db.query(_table, orderBy: 'scheduled_at ASC');
    return rows.map(InterventionModel.fromMap).toList();
  }

  Future<InterventionModel?> getById(String id) async {
    final db = await _appDb.database;
    final rows =
        await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return InterventionModel.fromMap(rows.first);
  }

  /// Insère, ou remplace si l'id existe déjà.
  Future<void> insertOrReplace(InterventionModel model) async {
    final db = await _appDb.database;
    await db.insert(_table, model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(InterventionModel model) async {
    final db = await _appDb.database;
    await db.update(_table, model.toMap(),
        where: 'id = ?', whereArgs: [model.id]);
  }

  /// Utilisé quand on reçoit la liste du serveur.
  /// Les lignes modifiées en local (pending) ne sont PAS écrasées.
  Future<void> upsertAllFromRemote(List<InterventionModel> models) async {
    final db = await _appDb.database;
    await db.transaction((txn) async {
      for (final m in models) {
        final existing = await txn.query(
          _table,
          columns: ['sync_status'],
          where: 'id = ?',
          whereArgs: [m.id],
          limit: 1,
        );
        final isPending = existing.isNotEmpty &&
            existing.first['sync_status'] == SyncStatus.pending;
        if (isPending) continue;

        await txn.insert(_table, m.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateSyncStatus(String id, String syncStatus) async {
    final db = await _appDb.database;
    await db.update(_table, {'sync_status': syncStatus},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await _appDb.database;
    await db.delete(_table);
  }
}