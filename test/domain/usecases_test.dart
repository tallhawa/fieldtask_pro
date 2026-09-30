import 'package:fieldtask_pro/features/auth/domain/entities/auth_session.dart';
import 'package:fieldtask_pro/features/auth/domain/repositories/auth_repository.dart';
import 'package:fieldtask_pro/features/auth/domain/usecases/login.dart';
import 'package:fieldtask_pro/features/auth/domain/usecases/logout.dart';
import 'package:fieldtask_pro/features/auth/domain/usecases/restore_session.dart';
import 'package:fieldtask_pro/features/interventions/domain/entities/intervention.dart';
import 'package:fieldtask_pro/features/interventions/domain/repositories/intervention_repository.dart';
import 'package:fieldtask_pro/features/interventions/domain/usecases/add_note.dart';
import 'package:fieldtask_pro/features/interventions/domain/usecases/add_photo.dart';
import 'package:fieldtask_pro/features/interventions/domain/usecases/create_intervention.dart';
import 'package:fieldtask_pro/features/interventions/domain/usecases/get_intervention_by_id.dart';
import 'package:fieldtask_pro/features/interventions/domain/usecases/get_interventions.dart';
import 'package:fieldtask_pro/features/interventions/domain/usecases/save_signature.dart';
import 'package:fieldtask_pro/features/interventions/domain/usecases/sync_now.dart';
import 'package:fieldtask_pro/features/interventions/domain/usecases/update_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInterventionRepository extends Mock
    implements InterventionRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockInterventionRepository repo;
  late MockAuthRepository authRepo;

  final intervention = Intervention(
    id: 'i1',
    title: 'Panne routeur',
    clientName: 'Client',
    address: 'Dakar',
    description: 'Desc',
    equipment: 'Routeur',
    status: InterventionStatus.pending,
    priority: InterventionPriority.high,
    latitude: 14.69,
    longitude: -17.44,
    scheduledAt: DateTime.utc(2026, 10, 1, 9),
    updatedAt: DateTime.utc(2026, 9, 30, 8),
  );

  const session = AuthSession(
    userId: 'u1',
    name: 'Technicien Test',
    email: 'tech@techfix.sn',
    token: 'jwt-simule-abc123',
  );

  setUp(() {
    repo = MockInterventionRepository();
    authRepo = MockAuthRepository();
  });

  test('GetInterventions renvoie la liste du repository', () async {
    when(() => repo.getInterventions()).thenAnswer((_) async => [intervention]);

    final result = await GetInterventions(repo)();

    expect(result, [intervention]);
  });

  test('GetInterventionById renvoie l\'intervention, ou null si inconnue',
      () async {
    when(() => repo.getById('i1')).thenAnswer((_) async => intervention);
    when(() => repo.getById('zzz')).thenAnswer((_) async => null);

    expect(await GetInterventionById(repo)('i1'), intervention);
    expect(await GetInterventionById(repo)('zzz'), isNull);
  });

  test('les use cases d\'écriture délèguent au repository', () async {
    when(() => repo.updateStatus('i1', InterventionStatus.done))
        .thenAnswer((_) async {});
    when(() => repo.updateNotes('i1', 'RAS')).thenAnswer((_) async {});
    when(() => repo.addPhoto('i1', 'a.jpg')).thenAnswer((_) async {});
    when(() => repo.saveSignature('i1', 'sig.png')).thenAnswer((_) async {});
    when(() => repo.createIntervention(intervention)).thenAnswer((_) async {});
    when(() => repo.syncNow()).thenAnswer((_) async {});

    await UpdateStatus(repo)('i1', InterventionStatus.done);
    await AddNote(repo)('i1', 'RAS');
    await AddPhoto(repo)('i1', 'a.jpg');
    await SaveSignature(repo)('i1', 'sig.png');
    await CreateIntervention(repo)(intervention);
    await SyncNow(repo)();

    verify(() => repo.updateStatus('i1', InterventionStatus.done)).called(1);
    verify(() => repo.updateNotes('i1', 'RAS')).called(1);
    verify(() => repo.addPhoto('i1', 'a.jpg')).called(1);
    verify(() => repo.saveSignature('i1', 'sig.png')).called(1);
    verify(() => repo.createIntervention(intervention)).called(1);
    verify(() => repo.syncNow()).called(1);
  });

  test('Login renvoie la session du repository', () async {
    when(() => authRepo.login('tech@techfix.sn', '1234'))
        .thenAnswer((_) async => session);

    final result = await Login(authRepo)('tech@techfix.sn', '1234');

    expect(result.token, 'jwt-simule-abc123');
  });

  test('RestoreSession renvoie null quand personne n\'est connecté', () async {
    when(() => authRepo.restoreSession()).thenAnswer((_) async => null);

    expect(await RestoreSession(authRepo)(), isNull);
  });

  test('Logout délègue au repository', () async {
    when(() => authRepo.logout()).thenAnswer((_) async {});

    await Logout(authRepo)();

    verify(() => authRepo.logout()).called(1);
  });
}