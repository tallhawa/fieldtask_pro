import '../repositories/intervention_repository.dart';

class SaveSignature {
  final InterventionRepository repository;
  SaveSignature(this.repository);

  /// [signaturePath] : chemin local de l'image de la signature du client.
  Future<void> call(String id, String signaturePath) =>
      repository.saveSignature(id, signaturePath);
}