import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';

final receiverGuidesProvider = StreamProvider<List<Guide>>((ref) {
  final db = ref.watch(dbProvider);
  return db.watchAllGuides();
});

class ReceiverGuidesListScreen extends ConsumerWidget {
  const ReceiverGuidesListScreen({super.key});

  Future<void> _leaveUserView(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave User View?'),
        content: const Text('Return to the main screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      context.go('/receiver');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidesAsync = ref.watch(receiverGuidesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Guide'),
        actions: [
          GestureDetector(
            onLongPress: () => _leaveUserView(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.exit_to_app, color: Colors.grey),
                  SizedBox(height: 2),
                  Text(
                    'Hold',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'receiver_list_home_fab',
        onPressed: null,
        label: GestureDetector(
          onLongPress: () => _leaveUserView(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home),
              SizedBox(width: 8),
              Text('Hold for Home'),
            ],
          ),
        ),
      ),
      body: guidesAsync.when(
        data: (guides) {
          if (guides.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No guides available.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: guides.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final g = guides[i];

              return Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => context.push('/receiver/guides/${g.id}/play'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _GuideThumbLarge(path: g.coverPhotoPath),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap to start this guide',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            size: 32,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _GuideThumbLarge extends StatelessWidget {
  final String? path;
  const _GuideThumbLarge({required this.path});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    if (path == null || path!.isEmpty) {
      return Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Icon(Icons.menu_book, size: 40),
      );
    }

    final file = File(path!);

    if (!file.existsSync()) {
      return Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Icon(Icons.broken_image, size: 40),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.file(
        file,
        width: 92,
        height: 92,
        fit: BoxFit.cover,
      ),
    );
  }
}
