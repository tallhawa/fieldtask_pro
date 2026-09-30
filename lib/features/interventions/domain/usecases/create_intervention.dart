import '../entities/intervention.dart';
import '../repositories/intervention_repository.dart';

class CreateIntervention {
  final InterventionRepository repository;
  CreateIntervention(this.repository);

  Future<void> call(Intervention intervention) =>
      repository.createIntervention(intervention);
}