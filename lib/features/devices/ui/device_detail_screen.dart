import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';

final deviceProvider = FutureProvider.family<Device?, int>((ref, id) {
  final db = ref.watch(dbProvider);
  return db.getDeviceById(id);
});

final guidesStreamProvider = StreamProvider.family<List<Guide>, int>((ref, deviceId) {
  final db = ref.watch(dbProvider);
  return db.watchGuidesForDevice(deviceId);
});

class DeviceDetailScreen extends ConsumerWidget {
  final int deviceId;
  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceProvider(deviceId));
    final guidesAsync = ref.watch(guidesStreamProvider(deviceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Device')),
      body: deviceAsync.when(
        data: (device) {
          if (device == null) {
            return const Center(child: Text('Device not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (device.coverPhotoPath != null && device.coverPhotoPath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(device.coverPhotoPath!), height: 180, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              Text(device.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text('Guides', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _createGuideDialog(context, ref, deviceId),
                    icon: const Icon(Icons.add),
                    label: const Text('Add guide'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              guidesAsync.when(
                data: (guides) {
                  if (guides.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Text('No guides yet. Tap “Add guide”.'),
                    );
                  }

                  return Column(
                    children: guides
                        .map(
                          (g) => Card(
                        child: ListTile(
                          title: Text(g.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          subtitle: Text('Created: ${g.createdAt.toLocal()}'.split('.').first),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.go('/devices/$deviceId/guides/${g.id}');
                          },


                        ),
                      ),
                    )
                        .toList(),
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
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

  Future<void> _createGuideDialog(BuildContext context, WidgetRef ref, int deviceId) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('New guide'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Turn on TV'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Create')),
          ],
        );
      },
    );

    final title = (result ?? '').trim();
    if (title.isEmpty) return;

    final db = ref.read(dbProvider);
    await db.createGuide(deviceId: deviceId, title: title);
  }
}
