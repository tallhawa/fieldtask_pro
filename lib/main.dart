import 'package:flutter/material.dart';

import 'core/di/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Couche données prête : B branche ici son application (Riverpod / BLoC).
  final dependencies = await AppDependencies.create();
  final session = await dependencies.restoreSession();

  runApp(MaterialApp(
    title: 'FieldTask Pro',
    home: Scaffold(
      body: Center(
        child: Text(
          session == null
              ? 'FieldTask Pro : connexion requise'
              : 'Bonjour ${session.name}',
        ),
      ),
    ),
  ));
}