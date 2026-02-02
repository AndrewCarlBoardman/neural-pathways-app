import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class CaregiverGuidesApp extends ConsumerWidget {
  const CaregiverGuidesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Caregiver Guides',
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaleFactor: (mq.textScaleFactor * 1.08).clamp(1.0, 1.3),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },

    );
  }
}
