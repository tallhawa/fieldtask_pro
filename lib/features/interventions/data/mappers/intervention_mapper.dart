import '../../../../core/constants/sync_status.dart';
import '../../domain/entities/intervention.dart';
import '../models/intervention_model.dart';

class InterventionMapper {
  static Intervention toEntity(InterventionModel m) {
    return Intervention(
      id: m.id,
      title: m.title,
      clientName: m.clientName,
      address: m.address,
      description: m.description,
      equipment: m.equipment,
      status: InterventionStatus.values.byName(m.status),
      priority: InterventionPriority.values.byName(m.priority),
      latitude: m.latitude,
      longitude: m.longitude,
      scheduledAt: DateTime.parse(m.scheduledAt),
      notes: m.notes,
      photoPaths: m.photoPaths,
      signaturePath: m.signaturePath,
      updatedAt: DateTime.parse(m.updatedAt),
    );
  }

  static InterventionModel toModel(
    Intervention e, {
    String syncStatus = SyncStatus.synced,
  }) {
    return InterventionModel(
      id: e.id,
      title: e.title,
      clientName: e.clientName,
      address: e.address,
      description: e.description,
      equipment: e.equipment,
      status: e.status.name,
      priority: e.priority.name,
      latitude: e.latitude,
      longitude: e.longitude,
      scheduledAt: e.scheduledAt.toUtc().toIso8601String(),
      notes: e.notes,
      photoPaths: e.photoPaths,
      signaturePath: e.signaturePath,
      updatedAt: e.updatedAt.toUtc().toIso8601String(),
      syncStatus: syncStatus,
    );
  }
}