import '../entities/intervention.dart';

abstract class InterventionRepository {
  Future<List<Intervention>> getInterventions();
  Future<Intervention?> getById(String id);
  Future<void> createIntervention(Intervention intervention); // ⬅ NOUVEAU
  Future<void> updateStatus(String id, InterventionStatus status);
  Future<void> updateNotes(String id, String notes);
  Future<void> addPhoto(String id, String photoPath);
  Future<void> saveSignature(String id, String signaturePath);
  Future<void> syncNow();
}