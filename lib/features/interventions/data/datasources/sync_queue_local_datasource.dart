import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/sync_queue_item.dart';

class SyncQueueLocalDataSource {
  final AppDatabase _appDb;
  SyncQueueLocalDataSource(this._appDb);

  static const _table = AppDatabase.tableSyncQueue;

  Future<int> enqueue(SyncQueueItem item) async {
    final db = await _appDb.database;
    return db.insert(_table, item.toMap());
  }

  /// Ordre d'arrivée (FIFO) : le plus ancien d'abord.
  Future<List<SyncQueueItem>> getAll() async {
    final db = await _appDb.database;
    final rows = await db.query(_table, orderBy: 'id ASC');
    return rows.map(SyncQueueItem.fromMap).toList();
  }

  Future<void> remove(int id) async {
    final db = await _appDb.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetry(int id) async {
    final db = await _appDb.database;
    await db.rawUpdate(
      'UPDATE $_table SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> count() async {
    final db = await _appDb.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clear() async {
    final db = await _appDb.database;
    await db.delete(_table);
  }
}