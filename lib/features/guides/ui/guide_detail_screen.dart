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

  Future<bool> _confirmDelete(BuildContext context, Step step) async {
    return (await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete step?'),
        content: Text(
          'This will permanently delete “Step ${step.stepIndex}”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    )) ??
        false;
  }

  Future<void> _deleteStep(BuildContext context, WidgetRef ref, Step step) async {
    final ok = await _confirmDelete(context, step);
    if (!ok) return;

    try {
      final db = ref.read(dbProvider);

      // Assumes you have something like: Future<void> deleteStep(int stepId)
      // If your method name differs, adjust this line.
      await db.deleteStep(step.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted Step ${step.stepIndex}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(guideProvider(guideId));
    final stepsAsync = ref.watch(stepsStreamProvider(guideId));

    // Current screen path (e.g. /guides/12)
    final basePath = GoRouterState.of(context).uri.path;

    return Scaffold(
      appBar: AppBar(title: const Text('Guide')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('$basePath/steps/new'),
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
                        onPressed: steps.isEmpty ? null : () => context.go('$basePath/play'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play (User View)'),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Steps',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      if (steps.isEmpty) const Text('No steps yet. Tap “Add Step”.'),

                      ...steps.map((s) {
                        return Dismissible(
                          key: ValueKey('step_${s.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(context, s),
                          onDismissed: (_) => _deleteStep(context, ref, s),
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                          child: Card(
                            child: ListTile(
                              onTap: () {
                                // Tap to edit (see router note below)
                                context.go('$basePath/steps/${s.id}/edit');
                              },
                              title: Text(
                                'Step ${s.stepIndex}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                s.instructionText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteStep(context, ref, s),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
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
