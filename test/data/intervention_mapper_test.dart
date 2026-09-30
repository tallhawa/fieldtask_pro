import 'package:fieldtask_pro/core/constants/sync_status.dart';
import 'package:fieldtask_pro/features/interventions/data/mappers/intervention_mapper.dart';
import 'package:fieldtask_pro/features/interventions/domain/entities/intervention.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entity = Intervention(
    id: 'i1',
    title: 'Panne routeur',
    clientName: 'Client',
    address: 'Dakar',
    description: 'Desc',
    equipment: 'Routeur',
    status: InterventionStatus.inProgress,
    priority: InterventionPriority.high,
    latitude: 14.69,
    longitude: -17.44,
    scheduledAt: DateTime.utc(2026, 10, 1, 9),
    updatedAt: DateTime.utc(2026, 9, 30, 8),
    notes: 'RAS',
    photoPaths: const ['a.jpg', 'b.jpg'],
    signaturePath: 'sig.png',
  );

  test('toModel convertit les énumérations en texte', () {
    final model = InterventionMapper.toModel(entity);

    expect(model.status, 'inProgress');
    expect(model.priority, 'high');
  });

  test('toModel applique le statut de synchro demandé (synced par défaut)', () {
    expect(InterventionMapper.toModel(entity).syncStatus, SyncStatus.synced);
    expect(
      InterventionMapper.toModel(entity, syncStatus: SyncStatus.pending)
          .syncStatus,
      SyncStatus.pending,
    );
  });

  test('aller-retour Entity -> Model -> Entity sans perte', () {
    final back =
        InterventionMapper.toEntity(InterventionMapper.toModel(entity));

    expect(back, entity);
    expect(back.title, 'Panne routeur');
    expect(back.scheduledAt, DateTime.utc(2026, 10, 1, 9));
    expect(back.photoPaths, ['a.jpg', 'b.jpg']);
  });
}