import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';

final editGuideProvider = FutureProvider.family<Guide?, int>((ref, id) {
  final db = ref.watch(dbProvider);
  return db.getGuideById(id);
});

class GuideEditScreen extends ConsumerStatefulWidget {
  final int guideId;
  const GuideEditScreen({super.key, required this.guideId});

  @override
  ConsumerState<GuideEditScreen> createState() => _GuideEditScreenState();
}

class _GuideEditScreenState extends ConsumerState<GuideEditScreen> {
  final _titleController = TextEditingController();
  final _picker = ImagePicker();

  bool _initialized = false;
  bool _saving = false;
  String? _pickedImagePath;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
    );

    if (picked == null) return;

    setState(() {
      _pickedImagePath = picked.path;
    });
  }

  Future<String?> _copyGuideImage(String? sourcePath) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final guidesDir = Directory(p.join(docsDir.path, 'guide_covers'));

    if (!guidesDir.existsSync()) {
      guidesDir.createSync(recursive: true);
    }

    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final filename = 'guide_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(guidesDir.path, filename);

    final copied = await sourceFile.copy(destPath);
    return copied.path;
  }

  Future<void> _save(Guide guide) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);

    try {
      final db = ref.read(dbProvider);
      final newCoverPhotoPath = await _copyGuideImage(_pickedImagePath);

      await db.updateGuide(
        guideId: guide.id,
        title: title,
        coverPhotoPath: newCoverPhotoPath ?? guide.coverPhotoPath,
      );

      if (!mounted) return;
      context.go('/guides/${guide.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideAsync = ref.watch(editGuideProvider(widget.guideId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Guide')),
      body: guideAsync.when(
        data: (guide) {
          if (guide == null) {
            return const Center(child: Text('Guide not found'));
          }

          if (!_initialized) {
            _titleController.text = guide.title;
            _initialized = true;
          }

          final previewPath = _pickedImagePath ?? guide.coverPhotoPath;
          final previewFile = (previewPath != null && previewPath.isNotEmpty)
              ? File(previewPath)
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Guide name',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_camera),
                label: Text(
                  previewFile == null ? 'Add Guide Image' : 'Change Guide Image',
                ),
              ),
              if (previewFile != null && previewFile.existsSync()) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    previewFile,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(guide),
                icon: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Changes'),
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
