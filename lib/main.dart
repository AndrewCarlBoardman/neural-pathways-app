import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  runZonedGuarded(
        () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
        debugPrintStack(stackTrace: details.stack);
      };

      ErrorWidget.builder = (details) {
        return Material(
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Something went wrong while starting Caregiver Guides.\n\n${details.exceptionAsString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
      };

      runApp(const ProviderScope(child: CaregiverGuidesApp()));
    },
        (error, stackTrace) {
      debugPrint('UNCAUGHT STARTUP ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}
