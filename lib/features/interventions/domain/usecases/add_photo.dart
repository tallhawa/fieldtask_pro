import '../repositories/intervention_repository.dart';

class AddPhoto {
  final InterventionRepository repository;
  AddPhoto(this.repository);

  /// [photoPath] : chemin local de la photo prise par l'appareil.
  Future<void> call(String id, String photoPath) =>
      repository.addPhoto(id, photoPath);
}