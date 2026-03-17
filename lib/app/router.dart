import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:caregiver_guides/features/guides/ui/guide_create_screen.dart';
import 'package:caregiver_guides/features/guides/ui/guide_detail_screen.dart';
import 'package:caregiver_guides/features/guides/ui/guide_edit_screen.dart';
import 'package:caregiver_guides/features/guides/ui/guides_list_screen.dart';
import 'package:caregiver_guides/features/receiver/ui/receiver_guides_list_screen.dart';
import 'package:caregiver_guides/features/receiver/ui/receiver_home_screen.dart';

// Prefix these two to guarantee no symbol confusion
import '../features/steps/ui/step_create_screen.dart' as step_create;
import '../features/steps/ui/step_viewer_screen.dart' as step_viewer;

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/receiver',
    routes: [
      GoRoute(
        path: '/receiver',
        builder: (context, state) => const ReceiverHomeScreen(),
      ),
      GoRoute(
        path: '/receiver/guides',
        builder: (context, state) => const ReceiverGuidesListScreen(),
      ),
      GoRoute(
        path: '/receiver/guides/:guideId/play',
        builder: (context, state) {
          final guideId = int.parse(state.pathParameters['guideId']!);
          return step_viewer.StepViewerScreen(guideId: guideId);
        },
      ),
      GoRoute(
        path: '/guides',
        builder: (context, state) => const GuidesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const GuideCreateScreen(),
          ),
          GoRoute(
            path: ':guideId',
            builder: (context, state) {
              final guideId = int.parse(state.pathParameters['guideId']!);
              return GuideDetailScreen(guideId: guideId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final guideId = int.parse(state.pathParameters['guideId']!);
                  return GuideEditScreen(guideId: guideId);
                },
              ),
              GoRoute(
                path: 'steps/new',
                builder: (context, state) {
                  final guideId = int.parse(state.pathParameters['guideId']!);
                  return step_create.StepCreateScreen(guideId: guideId);
                },
              ),
              GoRoute(
                path: 'steps/:stepId/edit',
                builder: (context, state) {
                  final guideId = int.parse(state.pathParameters['guideId']!);
                  final stepId = int.parse(state.pathParameters['stepId']!);
                  return step_create.StepCreateScreen(
                    guideId: guideId,
                    stepId: stepId,
                  );
                },
              ),
              GoRoute(
                path: 'play',
                builder: (context, state) {
                  final guideId = int.parse(state.pathParameters['guideId']!);
                  return step_viewer.StepViewerScreen(guideId: guideId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
