import '../entities/intervention.dart';
import '../repositories/intervention_repository.dart';

class UpdateStatus {
  final InterventionRepository repository;
  UpdateStatus(this.repository);

  Future<void> call(String id, InterventionStatus status) =>
      repository.updateStatus(id, status);
}