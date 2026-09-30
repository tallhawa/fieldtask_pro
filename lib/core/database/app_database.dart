import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String tableInterventions = 'interventions';
  static const String tableSyncQueue = 'sync_queue';

  static const String _dbName = 'fieldtask.db';
  static const int _dbVersion = 1;

  /// [path] sert uniquement aux tests (ex. inMemoryDatabasePath).
  AppDatabase({String? path}) : _path = path;

  final String? _path;
  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = _path ?? join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableInterventions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        client_name TEXT NOT NULL,
        address TEXT NOT NULL,
        description TEXT NOT NULL,
        equipment TEXT NOT NULL,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        scheduled_at TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        photo_paths TEXT NOT NULL DEFAULT '[]',
        signature_path TEXT,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_interventions_status ON $tableInterventions(status)',
    );

    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        intervention_id TEXT NOT NULL,
        action_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}