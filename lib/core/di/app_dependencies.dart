import '../../features/interventions/data/datasources/intervention_local_datasource.dart';
import '../../features/interventions/data/datasources/intervention_remote_datasource.dart';
import '../../features/interventions/data/datasources/sync_queue_local_datasource.dart';
import '../../features/interventions/data/repositories/intervention_repository_impl.dart';
import '../../features/interventions/data/sync/sync_engine.dart';
import '../../features/interventions/domain/repositories/intervention_repository.dart';
import '../../features/interventions/domain/usecases/add_note.dart';
import '../../features/interventions/domain/usecases/add_photo.dart';
import '../../features/interventions/domain/usecases/create_intervention.dart';
import '../../features/interventions/domain/usecases/get_intervention_by_id.dart';
import '../../features/interventions/domain/usecases/get_interventions.dart';
import '../../features/interventions/domain/usecases/save_signature.dart';
import '../../features/interventions/domain/usecases/sync_now.dart';
import '../../features/interventions/domain/usecases/update_status.dart';
import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import '../network/dio_client.dart';

class AppDependencies {
  AppDependencies._({
    required this.database,
    required this.syncEngine,
    required this.interventionRepository,
  })  : getInterventions = GetInterventions(interventionRepository),
        getInterventionById = GetInterventionById(interventionRepository),
        createIntervention = CreateIntervention(interventionRepository),
        updateStatus = UpdateStatus(interventionRepository),
        addNote = AddNote(interventionRepository),
        addPhoto = AddPhoto(interventionRepository),
        saveSignature = SaveSignature(interventionRepository),
        syncNow = SyncNow(interventionRepository);

  final AppDatabase database;
  final SyncEngine syncEngine;
  final InterventionRepository interventionRepository;

  final GetInterventions getInterventions;
  final GetInterventionById getInterventionById;
  final CreateIntervention createIntervention;
  final UpdateStatus updateStatus;
  final AddNote addNote;
  final AddPhoto addPhoto;
  final SaveSignature saveSignature;
  final SyncNow syncNow;

  /// [database] et [baseUrl] permettent de tester (autre base, serveur factice).
  static Future<AppDependencies> create({
    AppDatabase? database,
    String? baseUrl,
    TokenProvider? tokenProvider,
  }) async {
    final db = database ?? AppDatabase();
    final dio = createDio(tokenProvider: tokenProvider, baseUrl: baseUrl);

    final local = InterventionLocalDataSource(db);
    final queue = SyncQueueLocalDataSource(db);
    final remote = InterventionRemoteDataSource(dio);

    final engine = SyncEngine(
      local: local,
      remote: remote,
      queue: queue,
      connectivity: ConnectivityService(),
    );
    final repository = InterventionRepositoryImpl(
      local: local,
      queue: queue,
      syncEngine: engine,
    );

    await engine.start();

    return AppDependencies._(
      database: db,
      syncEngine: engine,
      interventionRepository: repository,
    );
  }

  /// Arrête la synchro (la base reste ouverte).
  Future<void> dispose() => syncEngine.dispose();
}