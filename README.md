# FieldTask Pro

Application mobile Flutter offline-first pour techniciens de terrain (TechFix).

## Prérequis
Flutter SDK, Android Studio (émulateur) et Node.js.

## Lancer le backend de test
```bash
cd backend
npx json-server@0.17.4 --watch db.json --port 3000 --host 0.0.0.0 --middlewares ./auth.js
```
Compte de test : `tech@techfix.sn` / `1234`.
Pour remettre les données à zéro : recopier `backend/db.seed.json` sur `backend/db.json`.

## Lancer l'application
```bash
flutter pub get
flutter run
```
- Émulateur Android : le serveur est joint par `http://10.0.2.2:3000` (défaut).
- Téléphone réel (même Wi-Fi que le PC) :
  `flutter run --dart-define=API_BASE_URL=http://IP_DU_PC:3000`

## Lancer les tests
```bash
flutter analyze
flutter test
```

## Architecture
Trois couches par fonctionnalité : `domain` (entités, use cases, interfaces),
`data` (modèles, mappers, sources SQLite et REST, repositories, synchro),
`presentation` (écrans). Voir le rapport technique.