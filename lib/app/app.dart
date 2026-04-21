import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router.dart';
import 'theme.dart';

class CaregiverGuidesApp extends ConsumerStatefulWidget {
  const CaregiverGuidesApp({super.key});

  @override
  ConsumerState<CaregiverGuidesApp> createState() => _CaregiverGuidesAppState();
}

class _CaregiverGuidesAppState extends ConsumerState<CaregiverGuidesApp> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _initRouter();
  }

  Future<void> _initRouter() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    final initialLocation = hasSeenOnboarding ? '/receiver' : '/onboarding';

    setState(() {
      _router = createAppRouter(initialLocation: initialLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) {
      return MaterialApp(
        title: 'Clear Steps',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const Scaffold(
          backgroundColor: Color(0xFFF7F7FA),
          body: SizedBox.shrink(),
        ),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.linear(
                (mq.textScaler.textScaleFactor * 1.06).clamp(1.0, 1.25),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
    }

    return MaterialApp.router(
      title: 'Clear Steps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router!,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
              (mq.textScaler.textScaleFactor * 1.06).clamp(1.0, 1.25),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}