# Guide pour la partie B (interface)

Tu travailles uniquement dans `presentation/` :
`lib/features/auth/presentation` et `lib/features/interventions/presentation`.
Besoin d'un nouveau use case (recherche, filtre...) ? Demande à A.

## Lancer
Voir le README (backend JSON-Server avec `--middlewares ./auth.js`).
Compte de test : `tech@techfix.sn` / `1234`.

## Démarrage
```dart
final app = await AppDependencies.create();      // core/di/app_dependencies.dart
final session = await app.restoreSession();      // null -> Login, sinon accueil
```

## Authentification
| Action | Appel | Erreurs possibles |
|---|---|---|
| Connexion | `await app.signIn(email, mdp)` | `AuthException`, `NetworkException` (1re connexion sans réseau) |
| Déconnexion | `await app.signOut()` | renvoie `false` si des actions ne sont pas synchronisées |
| Session expirée | écouter `app.sessionExpired` | ramener l'utilisateur au Login |

## Interventions
| Besoin | Appel |
|---|---|
| Liste | `app.getInterventions()` |
| Détail | `app.getInterventionById(id)` |
| Création | `app.createIntervention(intervention)` (id via le package `uuid`) |
| Statut | `app.updateStatus(id, InterventionStatus.inProgress)` (`pending`, `inProgress`, `done`) |
| Notes | `app.addNote(id, texte)` |
| Photo | `app.addPhoto(id, cheminLocal)` |
| Signature | `app.saveSignature(id, cheminLocal)` |
| Synchro manuelle | `app.syncNow()` |

Champs d'une `Intervention` : id, title, clientName, address, description,
equipment, status, priority (`low`, `medium`, `high`), latitude, longitude,
scheduledAt, notes, photoPaths, signaturePath, updatedAt.

## Indicateur En ligne / Hors ligne
`app.syncEngine.stream` (et `.state`) émet un `SyncState` :
`isOnline`, `isSyncing`, `pendingCount`, `lastSyncAt`, `lastError`.
Recharger la liste quand `lastSyncAt` change.

## Photos et signature
Donner un **chemin de fichier local**. Copier d'abord le fichier dans le
dossier documents de l'app (`path_provider`), car le fichier temporaire
d'`image_picker` peut disparaître.

## À ajouter côté B
- Packages : state management (`flutter_riverpod` ou `flutter_bloc`),
  `flutter_map`, `latlong2`, `geolocator`, `image_picker`,
  `flutter_local_notifications`, `signature`.
- Permissions Android : `CAMERA`, `ACCESS_FINE_LOCATION`, `POST_NOTIFICATIONS`.
- Pas de `setState` seul pour la logique métier (exigence du sujet).
- Le filtre, le tri par priorité et la recherche se font sur la liste chargée.

## Travail à deux
Une branche chacun, `git pull` souvent. `pubspec.yaml` est modifié par les deux :
utiliser `flutter pub add` et résoudre les conflits avec soin.