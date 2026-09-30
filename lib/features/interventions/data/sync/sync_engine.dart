import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/sync_status.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/connectivity_service.dart';
import '../datasources/intervention_local_datasource.dart';
import '../datasources/intervention_remote_datasource.dart';
import '../datasources/sync_queue_local_datasource.dart';
import '../models/intervention_model.dart';
import 'sync_state.dart';

class SyncEngine {
  SyncEngine({
    required this.local,
    required this.remote,
    required this.queue,
    required this.connectivity,
    this.maxRetries = 5,
    this.retryInterval = const Duration(seconds: 30),
    this.canSync,
  });

  final InterventionLocalDataSource local;
  final InterventionRemoteDataSource remote;
  final SyncQueueLocalDataSource queue;
  final ConnectivityService connectivity;
  final int maxRetries;
  final Duration retryInterval;

  /// Si fourni et renvoie false (personne de connecté),
  /// aucune synchronisation n'a lieu.
  final Future<bool> Function()? canSync;

  final _controller = StreamController<SyncState>.broadcast();
  SyncState _state = const SyncState();
  StreamSubscription<bool>? _connSub;
  Timer? _timer;
  Future<void>? _running;
  bool _rerun = false;

  SyncState get state => _state;
  Stream<SyncState> get stream => _controller.stream;

  void _emit(SyncState s) {
    _state = s;
    if (!_controller.isClosed) {
      _controller.add(s);
    }
  }

  // ---------------------------------------------------------------- démarrage

  Future<void> start() async {
    final online = await connectivity.isOnline;

    _emit(
      _state.copyWith(
        isOnline: online,
        pendingCount: await queue.count(),
      ),
    );

    // Retour de la connexion -> on synchronise.
    _connSub = connectivity.onStatusChanged.listen((online) {
      if (online) {
        unawaited(sync());
      } else {
        _emit(_state.copyWith(isOnline: false));
      }
    });

    // Filet de sécurité : Wi-Fi actif mais serveur revenu plus tard.
    _timer = Timer.periodic(retryInterval, (_) {
      if (_state.pendingCount > 0) {
        unawaited(sync());
      }
    });

    if (online) {
      unawaited(sync());
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _connSub?.cancel();
    await _controller.close();
  }

  // ---------------------------------------------------------- point d'entrée

  /// À appeler après chaque modification locale (ne bloque pas).
  void requestSync() {
    unawaited(_refreshPending().then((_) => sync()));
  }

  Future<void> _refreshPending() async {
    _emit(
      _state.copyWith(
        pendingCount: await queue.count(),
      ),
    );
  }

  /// Lance une synchro, ou attend celle déjà en cours.
  /// Ne lève jamais d'exception.
  Future<void> sync() {
    final running = _running;

    if (running != null) {
      _rerun = true;
      return running;
    }

    return _running = _run();
  }

  Future<void> _run() async {
    try {
      do {
        _rerun = false;
        await _syncOnce();
      } while (_rerun);
    } finally {
      _running = null;
    }
  }

  // ------------------------------------------------------------ une passe

  Future<void> _syncOnce() async {
    final check = canSync;

    if (check != null && !await check()) {
      return;
    }

    if (!await connectivity.isOnline) {
      _emit(
        _state.copyWith(
          isOnline: false,
          pendingCount: await queue.count(),
        ),
      );
      return;
    }

    _emit(
      _state.copyWith(
        isSyncing: true,
        clearError: true,
      ),
    );

    try {
      final drained = await _pushQueue();

      if (drained) {
        await _pull();

        _emit(
          _state.copyWith(
            isOnline: true,
            lastSyncAt: DateTime.now(),
          ),
        );
      }
    } on NetworkException {
      _emit(
        _state.copyWith(
          isOnline: false,
          lastError: 'Serveur injoignable : nouvelle tentative plus tard',
        ),
      );
    } on AppException catch (e) {
      _emit(_state.copyWith(lastError: e.message));
    } catch (e) {
      _emit(_state.copyWith(lastError: e.toString()));
    } finally {
      _emit(
        _state.copyWith(
          isSyncing: false,
          pendingCount: await queue.count(),
        ),
      );
    }
  }

  // --------------------------------------------------------------- PUSH

  /// Envoie les actions dans l'ordre.
  /// Renvoie true si la file est entièrement traitée.
  Future<bool> _pushQueue() async {
    final items = await queue.getAll(); // FIFO

    for (final item in items) {
      final model = InterventionModel.fromJson(
        jsonDecode(item.payload) as Map<String, dynamic>,
      );

      try {
        await _pushWithConflictCheck(model);
      } on NetworkException {
        rethrow;
      } on AppException catch (e) {
        await queue.incrementRetry(item.id!);

        if (item.retryCount + 1 < maxRetries) {
          _emit(_state.copyWith(lastError: e.message));
          return false;
        }

        // Trop d'échecs : on abandonne cette action
        // pour ne pas bloquer la file.
        debugPrint(
          '[SYNC] Action abandonnée (${item.interventionId}) : $e',
        );
      }

      await queue.remove(item.id!);

      if (await queue.countForIntervention(item.interventionId) == 0) {
        await local.updateSyncStatus(
          item.interventionId,
          SyncStatus.synced,
        );
      }

      _emit(
        _state.copyWith(
          pendingCount: await queue.count(),
        ),
      );
    }

    return true;
  }

  /// Règle de conflit : « la dernière modification gagne »
  /// (champ updatedAt).
  Future<void> _pushWithConflictCheck(
    InterventionModel localModel,
  ) async {
    try {
      final server = await remote.fetchById(localModel.id);
      final serverDate = DateTime.parse(server.updatedAt);
      final localDate = DateTime.parse(localModel.updatedAt);

      if (serverDate.isAfter(localDate)) {
        // Le serveur a une version plus récente : elle gagne.
        await local.insertOrReplace(server);
        return;
      }
    } on NotFoundException {
      // Inconnue du serveur : c'est une création, on envoie.
    }

    await remote.push(localModel);
  }

  // --------------------------------------------------------------- PULL

  Future<void> _pull() async {
    final remoteList = await remote.fetchAll();

    // Les lignes « pending » ne sont jamais écrasées (voir phase 2).
    await local.upsertAllFromRemote(remoteList);
  }
}