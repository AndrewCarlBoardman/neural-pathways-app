import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';
import '../../highlights/highlight_editor_screen.dart';
import '../../highlights/highlight_overlay.dart';

class StepCreateScreen extends ConsumerStatefulWidget {
  final int guideId;
  final int? stepId; // null=create, non-null=edit

  const StepCreateScreen({
    super.key,
    required this.guideId,
    this.stepId,
  });

  @override
  ConsumerState<StepCreateScreen> createState() => _StepCreateScreenState();
}

class _StepCreateScreenState extends ConsumerState<StepCreateScreen> {
  final TextEditingController _textController = TextEditingController();

  bool _loading = true;
  String? _photoPath;

  int? _stepId; // local mutable step id (create -> becomes edit)
  Size? _imagePxSize; // used ONLY for aspect ratio

  bool get isEdit => _stepId != null;

  Stream<StepHighlight?> _highlightStream(AppDatabase db, int stepId) {
    return (db.select(db.stepHighlights)..where((t) => t.stepId.equals(stepId))).watchSingleOrNull();
  }

  @override
  void initState() {
    super.initState();
    _stepId = widget.stepId;
    _loadIfEditing();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _resolveImagePxSize(ImageProvider provider) {
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;

    listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() {
        _imagePxSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      });
      stream.removeListener(listener);
    }, onError: (e, st) {
      stream.removeListener(listener);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load image: $e')),
      );
    });

    stream.addListener(listener);
  }

  Future<void> _loadIfEditing() async {
    if (!isEdit) {
      setState(() => _loading = false);
      return;
    }

    final AppDatabase db = ref.read(dbProvider);

    final steps = await db.watchStepsForGuide(widget.guideId).first;
    Step? step;
    for (final s in steps) {
      if (s.id == _stepId) {
        step = s;
        break;
      }
    }

    if (step != null) {
      _textController.text = step.instructionText;
      _photoPath = step.photoPath;

      if (_photoPath != null && _photoPath!.isNotEmpty) {
        _resolveImagePxSize(FileImage(File(_photoPath!)));
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      _photoPath = picked.path;
      _imagePxSize = null;
    });

    _resolveImagePxSize(FileImage(File(picked.path)));
  }

  Future<int> _getNextIndex(AppDatabase db) async {
    final existing = await db.watchStepsForGuide(widget.guideId).first;
    final maxIndex = existing.isEmpty ? 0 : existing.map((s) => s.stepIndex).reduce(max);
    return maxIndex + 1;
  }

  Future<int> _ensureStepExists() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an instruction first.')),
      );
      throw StateError('instruction required');
    }

    final AppDatabase db = ref.read(dbProvider);

    if (isEdit) return _stepId!;

    final nextIndex = await _getNextIndex(db);

    final newId = await db.into(db.steps).insert(
      StepsCompanion(
        guideId: Value(widget.guideId),
        stepIndex: Value(nextIndex),
        instructionText: Value(text),
        photoPath: Value(_photoPath),
      ),
    );

    setState(() => _stepId = newId);
    return newId;
  }

  Future<void> _saveStep() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an instruction.')),
      );
      return;
    }

    final AppDatabase db = ref.read(dbProvider);

    if (isEdit) {
      await (db.update(db.steps)..where((t) => t.id.equals(_stepId!))).write(
        StepsCompanion(
          instructionText: Value(text),
          photoPath: Value(_photoPath),
        ),
      );
    } else {
      final nextIndex = await _getNextIndex(db);
      await db.into(db.steps).insert(
        StepsCompanion(
          guideId: Value(widget.guideId),
          stepIndex: Value(nextIndex),
          instructionText: Value(text),
          photoPath: Value(_photoPath),
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _deleteStep() async {
    if (!isEdit) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete step?'),
        content: const Text('This will permanently delete the step and its highlight.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final AppDatabase db = ref.read(dbProvider);

    // ✅ Use your DB helper (deletes highlight + step in a transaction)
    await db.deleteStep(_stepId!);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _editHighlight() async {
    if (_photoPath == null || _photoPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photo first.')),
      );
      return;
    }

    final int stepId;
    try {
      stepId = await _ensureStepExists();
    } catch (_) {
      return;
    }

    final AppDatabase db = ref.read(dbProvider);

    final existing = await (db.select(db.stepHighlights)..where((t) => t.stepId.equals(stepId)))
        .getSingleOrNull();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HighlightEditorScreen(
          stepId: stepId,
          imageProvider: FileImage(File(_photoPath!)),
          existing: existing,
          onSave: ({required x, required y, required w, required h}) async {
            final updated = await (db.update(db.stepHighlights)..where((t) => t.stepId.equals(stepId)))
                .write(
              StepHighlightsCompanion(
                shape: const Value(0),
                x: Value(x),
                y: Value(y),
                w: Value(w),
                h: Value(h),
              ),
            );

            if (updated == 0) {
              await db.into(db.stepHighlights).insert(
                StepHighlightsCompanion(
                  stepId: Value(stepId),
                  shape: const Value(0),
                  x: Value(x),
                  y: Value(y),
                  w: Value(w),
                  h: Value(h),
                ),
              );
            }
          },
          onDelete: () async {
            await (db.delete(db.stepHighlights)..where((t) => t.stepId.equals(stepId))).go();
          },
        ),
      ),
    );

    // Persist latest instruction/photo and force rebuild so overlay updates immediately.
    if (!mounted) return;
    if (_stepId == stepId) {
      final text = _textController.text.trim();
      await (db.update(db.steps)..where((t) => t.id.equals(stepId))).write(
        StepsCompanion(
          instructionText: Value(text),
          photoPath: Value(_photoPath),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final AppDatabase db = ref.read(dbProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Step' : 'New Step'),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Delete step',
              icon: const Icon(Icons.delete),
              onPressed: _deleteStep,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          children: [
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Instruction',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (_photoPath != null && _photoPath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _imagePxSize == null
                    ? SizedBox(
                  height: 220,
                  child: Image.file(File(_photoPath!), fit: BoxFit.contain),
                )
                    : AspectRatio(
                  // KEY: Match HighlightEditorScreen’s coordinate space (no cropping).
                  aspectRatio: _imagePxSize!.width / _imagePxSize!.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // KEY: Use BoxFit.fill within an aspect-correct box (same as editor)
                      Image.file(File(_photoPath!), fit: BoxFit.fill),

                      if (isEdit)
                        StreamBuilder<StepHighlight?>(
                          stream: _highlightStream(db, _stepId!),
                          builder: (context, snap) {
                            final h = snap.data;
                            if (h == null) return const SizedBox.shrink();
                            return HighlightOverlay(highlight: h);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text((_photoPath == null || _photoPath!.isEmpty) ? 'Add Photo' : 'Change Photo'),
                    onPressed: _pickImage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.crop_square),
                    label: Text(isEdit ? 'Edit Highlight' : 'Add Highlight'),
                    onPressed: _editHighlight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            FilledButton(
              onPressed: _saveStep,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(isEdit ? 'Save Changes' : 'Create Step'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
