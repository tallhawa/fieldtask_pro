import '../repositories/intervention_repository.dart';

class SyncNow {
  final InterventionRepository repository;
  SyncNow(this.repository);

  /// Force la synchronisation immédiate (bouton « Synchroniser »).
  Future<void> call() => repository.syncNow();
}