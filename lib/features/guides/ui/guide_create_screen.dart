import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../shared/db/db_provider.dart';

class GuideCreateScreen extends ConsumerStatefulWidget {
  const GuideCreateScreen({super.key});

  @override
  ConsumerState<GuideCreateScreen> createState() => _GuideCreateScreenState();
}

class _GuideCreateScreenState extends ConsumerState<GuideCreateScreen> {
  final _titleController = TextEditingController();
  final _picker = ImagePicker();

  String? _pickedImagePath;
  bool _saving = false;

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

  Future<void> _saveGuide() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);

    try {
      final db = ref.read(dbProvider);
      final coverPhotoPath = await _copyGuideImage(_pickedImagePath);

      final guideId = await db.createGuideInDefaultBucket(
        title: title,
        coverPhotoPath: coverPhotoPath,
      );

      if (!mounted) return;
      context.go('/guides/$guideId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create guide: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageFile =
    (_pickedImagePath != null && _pickedImagePath!.isNotEmpty)
        ? File(_pickedImagePath!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('New Guide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Guide name',
              hintText: 'e.g. Turn on the TV',
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_camera),
            label: Text(
              imageFile == null ? 'Add Guide Image (Optional)' : 'Retake Guide Image',
            ),
          ),
          if (imageFile != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                imageFile,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _saveGuide,
            icon: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.check),
            label: Text(_saving ? 'Creating...' : 'Create Guide'),
          ),
        ],
      ),
    );
  }
}
