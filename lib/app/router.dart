import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:caregiver_guides/features/devices/ui/device_create_screen.dart';
import 'package:caregiver_guides/features/devices/ui/device_detail_screen.dart';
import 'package:caregiver_guides/features/devices/ui/devices_list_screen.dart';
import 'package:caregiver_guides/features/guides/ui/guide_detail_screen.dart';

// Prefix these two to *guarantee* no symbol confusion
import '../features/steps/ui/step_create_screen.dart' as step_create;
import '../features/steps/ui/step_viewer_screen.dart' as step_viewer;


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/devices',
    routes: [
      GoRoute(
        path: '/devices',
        builder: (context, state) => const DevicesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const DeviceCreateScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return DeviceDetailScreen(deviceId: id);
            },
            routes: [
              GoRoute(
                path: 'guides/:guideId',
                builder: (context, state) {
                  final guideId = int.parse(state.pathParameters['guideId']!);
                  return GuideDetailScreen(guideId: guideId);
                },
                routes: [
                  // create new step
                  GoRoute(
                    path: 'steps/new',
                    builder: (context, state) {
                      final guideId = int.parse(state.pathParameters['guideId']!);
                      return step_create.StepCreateScreen(guideId: guideId);
                    },
                  ),

                  // edit existing step
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
      ),
    ],
  );
});
