import 'dart:async';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/restore_session.dart';
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
    required this.authRepository,
    required this.interventionLocal,
    required this.sessionExpiredController,
  })  : getInterventions = GetInterventions(interventionRepository),
        getInterventionById = GetInterventionById(interventionRepository),
        createIntervention = CreateIntervention(interventionRepository),
        updateStatus = UpdateStatus(interventionRepository),
        addNote = AddNote(interventionRepository),
        addPhoto = AddPhoto(interventionRepository),
        saveSignature = SaveSignature(interventionRepository),
        syncNow = SyncNow(interventionRepository),
        restoreSession = RestoreSession(authRepository),
        _login = Login(authRepository),
        _logout = Logout(authRepository);

  final AppDatabase database;
  final SyncEngine syncEngine;
  final InterventionRepository interventionRepository;
  final AuthRepository authRepository;

  final InterventionLocalDataSource interventionLocal;
  final StreamController<void> sessionExpiredController;

  // Interventions
  final GetInterventions getInterventions;
  final GetInterventionById getInterventionById;
  final CreateIntervention createIntervention;
  final UpdateStatus updateStatus;
  final AddNote addNote;
  final AddPhoto addPhoto;
  final SaveSignature saveSignature;
  final SyncNow syncNow;

  // Authentification
  final RestoreSession restoreSession;
  final Login _login;
  final Logout _logout;

  /// Émet quand le serveur refuse le token :
  /// l'UI doit revenir au login.
  Stream<void> get sessionExpired =>
      sessionExpiredController.stream;

  /// [database], [baseUrl] et [authLocal] permettent de tester.
  static Future<AppDependencies> create({
    AppDatabase? database,
    String? baseUrl,
    AuthLocalDataSource? authLocal,
  }) async {
    final db = database ?? AppDatabase();
    final auth = authLocal ?? AuthLocalDataSource();
    final expired = StreamController<void>.broadcast();

    final dio = createDio(
      baseUrl: baseUrl,
      tokenProvider: auth.readToken,
      onUnauthorized: () =>
          unawaited(_handleUnauthorized(auth, expired)),
    );

    final local = InterventionLocalDataSource(db);
    final queue = SyncQueueLocalDataSource(db);
    final remote = InterventionRemoteDataSource(dio);

    final engine = SyncEngine(
      local: local,
      remote: remote,
      queue: queue,
      connectivity: ConnectivityService(),
      canSync: auth.hasSession,
    );

    final interventionRepository = InterventionRepositoryImpl(
      local: local,
      queue: queue,
      syncEngine: engine,
    );

    final authRepository = AuthRepositoryImpl(
      remote: AuthRemoteDataSource(dio),
      local: auth,
    );

    await engine.start();

    return AppDependencies._(
      database: db,
      syncEngine: engine,
      interventionRepository: interventionRepository,
      authRepository: authRepository,
      interventionLocal: local,
      sessionExpiredController: expired,
    );
  }

  static Future<void> _handleUnauthorized(
    AuthLocalDataSource auth,
    StreamController<void> expired,
  ) async {
    if (!await auth.hasSession()) return;

    await auth.clear();

    if (!expired.isClosed) {
      expired.add(null);
    }
  }

  /// Connexion, puis lancement de la synchro.
  Future<AuthSession> signIn(
    String email,
    String password,
  ) async {
    final session = await _login(email, password);
    syncEngine.requestSync();
    return session;
  }

  /// Déconnexion : dernière tentative de synchro, puis session effacée.
  ///
  /// Les données locales ne sont supprimées que si tout est synchronisé.
  /// Renvoie true si elles ont été supprimées, false si des actions en
  /// attente les ont fait conserver.
  Future<bool> signOut() async {
    await syncEngine.sync();

    final allSynced =
        syncEngine.state.pendingCount == 0;

    if (allSynced) {
      await interventionLocal.deleteAll();
    }

    await _logout();

    return allSynced;
  }

  Future<void> dispose() async {
    await syncEngine.dispose();
    await sessionExpiredController.close();
  }
}