import 'package:flutter/material.dart';

import 'core/di/app_dependencies.dart';
import 'dev/phase5_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1er lancement : garde cette ligne. 2e lancement : mets-la en commentaire.
  try {
    await runPhase5Check();
  } catch (e, st) {
    debugPrint('[P5] ÉCHEC : $e\n$st');
  }

  final app = await AppDependencies.create();
  final session = await app.restoreSession();

  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text(
          session == null
              ? 'Aucune session : écran de connexion'
              : 'Session restaurée : ${session.name}\n(${session.email})',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    ),
  ));
}