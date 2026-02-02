import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/db/db_provider.dart';
import '../../../shared/files/image_store.dart';
import '../../highlights/highlight_editor_screen.dart';

class StepCreateScreen extends ConsumerStatefulWidget {
  final int guideId;
  const StepCreateScreen({super.key, required this.guideId});

  @override
  ConsumerState<StepCreateScreen> createState() => _StepCreateScreenState();
}

class _StepCreateScreenState extends ConsumerState<StepCreateScreen> {
  final _instructionController = TextEditingController();
  final _picker = ImagePicker();
  final _imageStore = const ImageStore();

  String? _savedPhotoPath;
  bool _saving = false;

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;

    final savedPath = await _imageStore.savePickedImageToAppDir(picked);
    setState(() => _savedPhotoPath = savedPath);
  }

  bool _validate() {
    final text = _instructionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a short instruction')),
      );
      return false;
    }
    return true;
  }

  Future<int?> _saveStepReturnId() async {
    if (!_validate()) return null;

    setState(() => _saving = true);
    try {
      final db = ref.read(dbProvider);
      final nextIndex = await db.nextStepIndexForGuide(widget.guideId);

      final stepId = await db.createStep(
        guideId: widget.guideId,
        stepIndex: nextIndex,
        instructionText: _instructionController.text.trim(),
        photoPath: _savedPhotoPath,
      );

      return stepId;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveOnly() async {
    final id = await _saveStepReturnId();
    if (id == null) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveAndAddHighlight() async {
    if (_savedPhotoPath == null || _savedPhotoPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Take a photo first, then add a highlight.')),
      );
      return;
    }

    final stepId = await _saveStepReturnId();
    if (stepId == null) return;

    final db = ref.read(dbProvider);
    final existing = await db.getHighlightForStep(stepId);

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HighlightEditorScreen(
          stepId: stepId,
          imageProvider: FileImage(File(_savedPhotoPath!)),
          existing: existing,
          onSave: ({required x, required y, required w, required h}) async {
            await db.upsertHighlight(stepId: stepId, shape: 0, x: x, y: y, w: w, h: h);
          },
          onDelete: () async {
            await db.deleteHighlightForStep(stepId);
          },
        ),
      ),
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final previewFile = (_savedPhotoPath == null) ? null : File(_savedPhotoPath!);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Step')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Step photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(),
              ),
              child: previewFile == null
                  ? const Center(child: Text('No photo yet'))
                  : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(previewFile, fit: BoxFit.cover),
              ),
            ),
          ),

          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take photo'),
          ),

          const SizedBox(height: 18),
          const Text('Instruction text', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          TextField(
            controller: _instructionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Keep it short and clear.\nExample: Tap “Read More”.',
            ),
          ),

          const SizedBox(height: 18),

          FilledButton(
            onPressed: _saving ? null : _saveOnly,
            child: _saving
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Save Step'),
          ),

          const SizedBox(height: 10),

          if (_savedPhotoPath != null && _savedPhotoPath!.isNotEmpty)
            OutlinedButton.icon(
              onPressed: _saving ? null : _saveAndAddHighlight,
              icon: const Icon(Icons.crop_square),
              label: const Text('Save & Add Highlight'),
            ),
        ],
      ),
    );
  }
}
