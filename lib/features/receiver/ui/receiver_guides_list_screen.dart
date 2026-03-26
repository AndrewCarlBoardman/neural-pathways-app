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
        title: const Text('Exit guide mode?'),
        content: const Text('Return to the main Caregiver Guides screen.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay in guides'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Guide'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'exit') {
                _leaveUserView(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'exit',
                child: Row(
                  children: [
                    Icon(Icons.home_rounded),
                    SizedBox(width: 10),
                    Text('Exit guide mode'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: guidesAsync.when(
        data: (guides) {
          if (guides.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No guides available yet.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            );
          }

          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: guides.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final guide = guides[i];

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => context.push('/receiver/guides/${guide.id}/play'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _GuideThumbLarge(path: guide.coverPhotoPath),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  guide.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to start this guide',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 34,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load guides.\n\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideThumbLarge extends StatelessWidget {
  final String? path;
  const _GuideThumbLarge({required this.path});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);

    if (path == null || path!.isEmpty) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Icon(Icons.menu_book_rounded, size: 42),
      );
    }

    final file = File(path!);

    if (!file.existsSync()) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Icon(Icons.broken_image_outlined, size: 42),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.file(
        file,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
      ),
    );
  }
}
