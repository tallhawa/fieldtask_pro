import '../repositories/intervention_repository.dart';

class AddNote {
  final InterventionRepository repository;
  AddNote(this.repository);

  Future<void> call(String id, String notes) =>
      repository.updateNotes(id, notes);
}