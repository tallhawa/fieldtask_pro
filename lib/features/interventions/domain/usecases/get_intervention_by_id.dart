import '../entities/intervention.dart';
import '../repositories/intervention_repository.dart';

class GetInterventionById {
  final InterventionRepository repository;
  GetInterventionById(this.repository);

  Future<Intervention?> call(String id) => repository.getById(id);
}