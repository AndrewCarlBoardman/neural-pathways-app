import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';

final guidesStreamProvider = StreamProvider<List<Guide>>((ref) {
  final db = ref.watch(dbProvider);
  return db.watchAllGuides();
});

class GuidesListScreen extends ConsumerWidget {
  const GuidesListScreen({super.key});

  Future<void> _showGuideActions(
      BuildContext context,
      WidgetRef ref,
      Guide guide,
      ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy guide'),
              onTap: () => Navigator.of(ctx).pop('copy'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete guide'),
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

    if (action == 'copy') {
      await _copyGuide(context, ref, guide);
    } else if (action == 'delete') {
      await _deleteGuide(context, ref, guide);
    }
  }

  Future<bool> _confirmDelete(BuildContext context, Guide guide) async {
    return (await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete guide?'),
        content: Text(
          'This will permanently delete “${guide.title}” and all its steps.',
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

  Future<void> _deleteGuide(
      BuildContext context,
      WidgetRef ref,
      Guide guide,
      ) async {
    final ok = await _confirmDelete(context, guide);
    if (!ok) return;

    try {
      final db = ref.read(dbProvider);
      await db.deleteGuide(guide.id);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted “${guide.title}”')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _copyGuide(
      BuildContext context,
      WidgetRef ref,
      Guide guide,
      ) async {
    try {
      final db = ref.read(dbProvider);
      await db.duplicateGuide(guide.id);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied “${guide.title}”')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copy failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidesAsync = ref.watch(guidesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guides'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Back to mode selection',
          onPressed: () => context.go('/receiver'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/guides/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Guide'),
      ),
      body: guidesAsync.when(
        data: (guides) {
          if (guides.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No guides yet.\nTap “Add Guide” to create the first one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: guides.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final g = guides[i];
              return Card(
                child: ListTile(
                  onTap: () => context.go('/guides/${g.id}'),
                  onLongPress: () => _showGuideActions(context, ref, g),
                  leading: _GuideThumb(path: g.coverPhotoPath),
                  title: Text(
                    g.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
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

class _GuideThumb extends StatelessWidget {
  final String? path;
  const _GuideThumb({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.menu_book));
    }

    final file = File(path!);
    return CircleAvatar(
      backgroundImage: file.existsSync() ? FileImage(file) : null,
      child: !file.existsSync() ? const Icon(Icons.broken_image) : null,
    );
  }
}