import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';

final guideProvider = FutureProvider.family<Guide?, int>((ref, id) {
  final db = ref.watch(dbProvider);
  return db.getGuideById(id);
});

final stepsStreamProvider = StreamProvider.family<List<Step>, int>((ref, guideId) {
  final db = ref.watch(dbProvider);
  return db.watchStepsForGuide(guideId);
});

class GuideDetailScreen extends ConsumerWidget {
  final int guideId;
  const GuideDetailScreen({super.key, required this.guideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(guideProvider(guideId));
    final stepsAsync = ref.watch(stepsStreamProvider(guideId));

    return Scaffold(
      appBar: AppBar(title: const Text('Guide')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('${GoRouterState.of(context).uri.path}/steps/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Step'),
      ),
      body: guideAsync.when(
        data: (guide) {
          if (guide == null) return const Center(child: Text('Guide not found'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                guide.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              stepsAsync.when(
                data: (steps) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: steps.isEmpty
                            ? null
                            : () => context.go('${GoRouterState.of(context).uri.path}/play'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play (User View)'),
                      ),
                      const SizedBox(height: 14),
                      const Text('Steps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      if (steps.isEmpty)
                        const Text('No steps yet. Tap “Add Step”.'),
                      ...steps.map((s) {
                        return Card(
                          child: ListTile(
                            title: Text(
                              'Step ${s.stepIndex}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              s.instructionText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )),
                error: (e, st) => Text('Error: $e'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
