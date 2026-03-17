import 'dart:io';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';
import '../../../shared/export/guide_pdf_exporter.dart';

final guideProvider = FutureProvider.family<Guide?, int>((ref, id) {
  final db = ref.watch(dbProvider);
  return db.getGuideById(id);
});

final stepsStreamProvider = StreamProvider.family<List<Step>, int>((ref, guideId) {
  final db = ref.watch(dbProvider);
  return db.watchStepsForGuide(guideId);
});

class GuideDetailScreen extends ConsumerStatefulWidget {
  final int guideId;
  const GuideDetailScreen({super.key, required this.guideId});

  @override
  ConsumerState<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends ConsumerState<GuideDetailScreen> {
  List<Step> _localSteps = const [];
  bool _exporting = false;

  void _syncLocalSteps(List<Step> incoming) {
    final incomingIds = incoming.map((s) => s.id).toList();
    final localIds = _localSteps.map((s) => s.id).toList();

    if (_localSteps.length != incoming.length ||
        localIds.length != incomingIds.length) {
      _localSteps = List<Step>.from(incoming);
      return;
    }

    for (int i = 0; i < incomingIds.length; i++) {
      if (incomingIds[i] != localIds[i]) {
        _localSteps = List<Step>.from(incoming);
        return;
      }
    }
  }

  Future<void> _showStepActions(BuildContext context, Step step) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy step'),
              onTap: () => Navigator.of(ctx).pop('copy'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete step'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (action == 'copy') {
      await _copyStep(context, step);
    } else if (action == 'delete') {
      await _deleteStep(context, step);
    }
  }

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

  Future<void> _deleteStep(BuildContext context, Step step) async {
    final ok = await _confirmDelete(context, step);
    if (!ok) return;

    try {
      final db = ref.read(dbProvider);
      await db.deleteStep(step.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted Step ${step.stepIndex}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _copyStep(BuildContext context, Step step) async {
    try {
      final db = ref.read(dbProvider);
      await db.duplicateStep(step.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied Step ${step.stepIndex}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copy failed: $e')),
      );
    }
  }

  Future<void> _persistReorder() async {
    try {
      final db = ref.read(dbProvider);
      final ids = _localSteps.map((s) => s.id).toList();
      await db.reorderSteps(guideId: widget.guideId, orderedStepIds: ids);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reorder failed: $e')),
      );
    }
  }

  Future<void> _exportPdf() async {
    if (_exporting) return;

    setState(() => _exporting = true);
    try {
      final db = ref.read(dbProvider);
      await GuidePdfExporter.exportAndShare(db: db, guideId: widget.guideId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideAsync = ref.watch(guideProvider(widget.guideId));
    final stepsAsync = ref.watch(stepsStreamProvider(widget.guideId));
    final basePath = GoRouterState.of(context).uri.path;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                context.go('$basePath/edit');
              } else if (value == 'pdf') {
                _exportPdf();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 12),
                    Text('Edit Guide'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'pdf',
                enabled: !_exporting,
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Export PDF')),
                    if (_exporting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('$basePath/steps/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Step'),
      ),
      body: guideAsync.when(
        data: (guide) {
          if (guide == null) {
            return const Center(child: Text('Guide not found'));
          }

          final hasCover =
              guide.coverPhotoPath != null && guide.coverPhotoPath!.isNotEmpty;
          final coverFile = hasCover ? File(guide.coverPhotoPath!) : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (coverFile != null && coverFile.existsSync()) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    coverFile,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                guide.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.go('$basePath/edit'),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Guide'),
              ),
              const SizedBox(height: 10),
              stepsAsync.when(
                data: (steps) {
                  _syncLocalSteps(steps);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: steps.isEmpty
                            ? null
                            : () => context.go('$basePath/play'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play (User View)'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: const [
                          Text(
                            'Steps',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Drag the handle to reorder',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (steps.isEmpty)
                        const Text('No steps yet. Tap “Add Step”.'),
                      if (steps.isNotEmpty)
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) async {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = _localSteps.removeAt(oldIndex);
                              _localSteps.insert(newIndex, item);
                            });

                            await _persistReorder();
                          },
                          itemCount: _localSteps.length,
                          itemBuilder: (context, i) {
                            final s = _localSteps[i];
                            return Card(
                              key: ValueKey('step_${s.id}'),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                onTap: () =>
                                    context.go('$basePath/steps/${s.id}/edit'),
                                leading: ReorderableDragStartListener(
                                  index: i,
                                  child: const Icon(Icons.drag_handle),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Step ${i + 1}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.instructionText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  tooltip: 'Step options',
                                  onSelected: (value) {
                                    if (value == 'copy') {
                                      _copyStep(context, s);
                                    } else if (value == 'delete') {
                                      _deleteStep(context, s);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem<String>(
                                      value: 'copy',
                                      child: Row(
                                        children: [
                                          Icon(Icons.copy),
                                          SizedBox(width: 12),
                                          Text('Copy step'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline),
                                          SizedBox(width: 12),
                                          Text('Delete step'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
