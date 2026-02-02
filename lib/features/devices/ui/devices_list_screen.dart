import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';

final devicesStreamProvider = StreamProvider<List<Device>>((ref) {
  final db = ref.watch(dbProvider);
  return db.watchDevices();
});

class DevicesListScreen extends ConsumerWidget {
  const DevicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/devices/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
      ),
      body: devicesAsync.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No devices yet.\nTap “Add Device” to create the first one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = devices[i];
              return ListTile(
                onTap: () => context.go('/devices/${d.id}'),
                leading: _DeviceThumb(path: d.coverPhotoPath),
                title: Text(d.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                subtitle: Text('Created: ${d.createdAt.toLocal()}'.split('.').first),
                trailing: const Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
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

class _DeviceThumb extends StatelessWidget {
  final String? path;
  const _DeviceThumb({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.devices));
    }
    final file = File(path!);
    return CircleAvatar(
      backgroundImage: file.existsSync() ? FileImage(file) : null,
      child: !file.existsSync() ? const Icon(Icons.broken_image) : null,
    );
  }
}
