import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/rendering.dart' show MatrixUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';
import '../../highlights/highlight_editor_screen.dart';
import '../../highlights/highlight_overlay.dart';

const int _slot2SortOrderBase = 1000;
const double _frameAspectRatio = 1.0;

final _annotationsForStepProvider =
StreamProvider.family<List<StepAnnotation>, int>((ref, stepId) {
  final db = ref.watch(dbProvider);
  return db.watchAnnotationsForStep(stepId);
});

class _StepImagesPayload {
  final _StepImageRef? a;
  final _StepImageRef? b;

  const _StepImagesPayload({required this.a, required this.b});

  static _StepImagesPayload fromPhotoPath(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _StepImagesPayload(a: null, b: null);
    }

    final s = raw.trim();

    if (!s.startsWith('{') && s.contains('||')) {
      final parts = s.split('||');
      final a = parts.isNotEmpty && parts[0].trim().isNotEmpty
          ? _StepImageRef(path: parts[0].trim())
          : null;
      final b = parts.length >= 2 && parts[1].trim().isNotEmpty
          ? _StepImageRef(path: parts[1].trim())
          : null;
      return _StepImagesPayload(a: a, b: b);
    }

    if (!s.startsWith('{')) {
      return _StepImagesPayload(a: _StepImageRef(path: s), b: null);
    }

    try {
      final map = jsonDecode(s) as Map<String, dynamic>;
      final aMap = map['a'] as Map<String, dynamic>?;
      final bMap = map['b'] as Map<String, dynamic>?;
      return _StepImagesPayload(
        a: aMap == null ? null : _StepImageRef.fromJson(aMap),
        b: bMap == null ? null : _StepImageRef.fromJson(bMap),
      );
    } catch (_) {
      return _StepImagesPayload(a: _StepImageRef(path: s), b: null);
    }
  }

  String? toPhotoPathString() {
    if (a == null && b == null) return null;
    final map = <String, dynamic>{
      'v': 1,
      if (a != null) 'a': a!.toJson(),
      if (b != null) 'b': b!.toJson(),
    };
    return jsonEncode(map);
  }
}

class _StepImageRef {
  final String path;
  final double scale;
  final double tx;
  final double ty;

  const _StepImageRef({
    required this.path,
    this.scale = 1.0,
    this.tx = 0.0,
    this.ty = 0.0,
  });

  File get file => File(path);

  static _StepImageRef fromJson(Map<String, dynamic> json) {
    return _StepImageRef(
      path: (json['p'] as String?) ?? '',
      scale: (json['s'] as num?)?.toDouble() ?? 1.0,
      tx: (json['x'] as num?)?.toDouble() ?? 0.0,
      ty: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'p': path,
      's': scale,
      'x': tx,
      'y': ty,
    };
  }
}

class StepCreateScreen extends ConsumerStatefulWidget {
  final int guideId;
  final int? stepId;

  const StepCreateScreen({
    super.key,
    required this.guideId,
    this.stepId,
  });

  @override
  ConsumerState<StepCreateScreen> createState() => _StepCreateScreenState();
}

class _StepCreateScreenState extends ConsumerState<StepCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instruction1Controller = TextEditingController();
  final _instruction2Controller = TextEditingController();

  bool _loading = true;
  bool _twoImages = false;
  _StepImageRef? _img1;
  _StepImageRef? _img2;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.stepId == null) {
      setState(() => _loading = false);
      return;
    }

    final db = ref.read(dbProvider);
    final step = await db.getStepById(widget.stepId!);
    if (step != null) {
      _instruction1Controller.text = step.instructionText;
      _instruction2Controller.text = step.instructionText2 ?? '';
      final payload = _StepImagesPayload.fromPhotoPath(step.photoPath);
      _img1 = payload.a;
      _img2 = payload.b;
      _twoImages = payload.b != null;
    }
    setState(() => _loading = false);
  }

  Future<void> _pickOrCaptureForSlot(int slot) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 92);
    if (picked == null) return;

    final initial = _StepImageRef(path: picked.path);
    final adjusted = await Navigator.of(context).push<_StepImageRef>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FrameAdjustScreen(initial: initial),
      ),
    );

    if (adjusted == null) return;

    setState(() {
      if (slot == 1) {
        _img1 = adjusted;
      } else {
        _img2 = adjusted;
      }
    });
  }

  Future<void> _adjustExisting(int slot) async {
    final current = (slot == 1) ? _img1 : _img2;
    if (current == null) return;

    final adjusted = await Navigator.of(context).push<_StepImageRef>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FrameAdjustScreen(initial: current),
      ),
    );
    if (adjusted == null) return;

    setState(() {
      if (slot == 1) {
        _img1 = adjusted;
      } else {
        _img2 = adjusted;
      }
    });
  }

  List<StepAnnotation> _annsForSlot(List<StepAnnotation> all, int slot) {
    if (slot == 1) {
      final filtered =
      all.where((a) => a.sortOrder < _slot2SortOrderBase).toList();
      filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return filtered;
    }
    final filtered =
    all.where((a) => a.sortOrder >= _slot2SortOrderBase).toList();
    filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return filtered;
  }

  Future<void> _openHighlightEditor(int slot) async {
    if (widget.stepId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save the step first, then edit highlights.'),
        ),
      );
      return;
    }

    final img = (slot == 1) ? _img1 : _img2;
    if (img == null) return;

    final db = ref.read(dbProvider);
    final allExisting = await db.getAnnotationsForStep(widget.stepId!);
    final existingForSlot = _annsForSlot(allExisting, slot);
    final imageProvider = FileImage(img.file);

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HighlightEditorScreen(
          stepId: widget.stepId!,
          imageProvider: imageProvider,
          framingScale: img.scale,
          framingTx: img.tx,
          framingTy: img.ty,
          existing: existingForSlot,
          onSave: (items) async {
            final keepOther = _annsForSlot(allExisting, slot == 1 ? 2 : 1);
            final rows = <StepAnnotationsCompanion>[];

            if (slot == 1) {
              for (var i = 0; i < items.length; i++) {
                final d = items[i];
                rows.add(
                  StepAnnotationsCompanion(
                    stepId: Value(widget.stepId!),
                    kind: Value(d.kind),
                    shapeType: Value(d.shapeType),
                    color: Value(d.color),
                    x: Value(d.x),
                    y: Value(d.y),
                    w: Value(d.w),
                    h: Value(d.h),
                    label: Value(d.label),
                    sortOrder: Value(i),
                  ),
                );
              }
              for (final a in keepOther) {
                rows.add(
                  StepAnnotationsCompanion(
                    stepId: Value(widget.stepId!),
                    kind: Value(a.kind),
                    shapeType: Value(a.shapeType),
                    color: Value(a.color),
                    x: Value(a.x),
                    y: Value(a.y),
                    w: Value(a.w),
                    h: Value(a.h),
                    label: Value(a.label),
                    sortOrder: Value(a.sortOrder),
                  ),
                );
              }
            } else {
              for (final a in keepOther) {
                rows.add(
                  StepAnnotationsCompanion(
                    stepId: Value(widget.stepId!),
                    kind: Value(a.kind),
                    shapeType: Value(a.shapeType),
                    color: Value(a.color),
                    x: Value(a.x),
                    y: Value(a.y),
                    w: Value(a.w),
                    h: Value(a.h),
                    label: Value(a.label),
                    sortOrder: Value(a.sortOrder),
                  ),
                );
              }
              for (var i = 0; i < items.length; i++) {
                final d = items[i];
                rows.add(
                  StepAnnotationsCompanion(
                    stepId: Value(widget.stepId!),
                    kind: Value(d.kind),
                    shapeType: Value(d.shapeType),
                    color: Value(d.color),
                    x: Value(d.x),
                    y: Value(d.y),
                    w: Value(d.w),
                    h: Value(d.h),
                    label: Value(d.label),
                    sortOrder: Value(_slot2SortOrderBase + i),
                  ),
                );
              }
            }

            rows.sort((a, b) => a.sortOrder.value.compareTo(b.sortOrder.value));
            await db.replaceAnnotationsForStep(
              stepId: widget.stepId!,
              rows: rows,
            );
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(dbProvider);
    final instruction1 = _instruction1Controller.text.trim();
    final instruction2 = _twoImages ? _instruction2Controller.text.trim() : '';

    final img2 = _twoImages ? _img2 : null;
    final payload = _StepImagesPayload(a: _img1, b: img2);

    if (widget.stepId == null) {
      final index = await db.nextStepIndexForGuide(widget.guideId);
      await db.createStep(
        guideId: widget.guideId,
        stepIndex: index,
        instructionText: instruction1,
        instructionText2: instruction2.isEmpty ? null : instruction2,
        photoPath: payload.toPhotoPathString(),
      );
    } else {
      await db.updateStep(
        stepId: widget.stepId!,
        instructionText: instruction1,
        instructionText2: instruction2.isEmpty ? null : instruction2,
        photoPath: payload.toPhotoPathString(),
      );

      if (!_twoImages) {
        final all = await db.getAnnotationsForStep(widget.stepId!);
        final keep =
        all.where((a) => a.sortOrder < _slot2SortOrderBase).toList();
        final rows = <StepAnnotationsCompanion>[];
        for (final a in keep) {
          rows.add(
            StepAnnotationsCompanion(
              stepId: Value(widget.stepId!),
              kind: Value(a.kind),
              shapeType: Value(a.shapeType),
              color: Value(a.color),
              x: Value(a.x),
              y: Value(a.y),
              w: Value(a.w),
              h: Value(a.h),
              label: Value(a.label),
              sortOrder: Value(a.sortOrder),
            ),
          );
        }
        await db.replaceAnnotationsForStep(stepId: widget.stepId!, rows: rows);
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _duplicateStep() async {
    if (widget.stepId == null) return;
    final db = ref.read(dbProvider);
    await db.duplicateStep(widget.stepId!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Step copied')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _deleteStep() async {
    if (widget.stepId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete step?'),
        content: const Text('This will delete the step and its highlights.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final db = ref.read(dbProvider);
    await db.deleteStep(widget.stepId!);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _instructionField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool requiredField,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (requiredField && (v == null || v.trim().isEmpty)) {
          return 'Please enter text';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stepId = widget.stepId;
    final annAsync = (stepId == null)
        ? const AsyncValue<List<StepAnnotation>>.data([])
        : ref.watch(_annotationsForStepProvider(stepId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.stepId == null ? 'Create Step' : 'Edit Step'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copy') {
                _duplicateStep();
              } else if (value == 'delete') {
                _deleteStep();
              } else if (value == 'save') {
                _save();
              }
            },
            itemBuilder: (context) => [
              if (widget.stepId != null)
                const PopupMenuItem<String>(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      SizedBox(width: 12),
                      Text('Copy step'),
                    ],
                  ),
                ),
              if (widget.stepId != null)
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline),
                      SizedBox(width: 12),
                      Text('Delete step'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.check),
                    SizedBox(width: 12),
                    Text('Save'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('1 image')),
                ButtonSegment(value: true, label: Text('2 images')),
              ],
              selected: {_twoImages},
              onSelectionChanged: (s) {
                final v = s.first;
                setState(() {
                  _twoImages = v;
                  if (!v) {
                    _img2 = null;
                    _instruction2Controller.clear();
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 14),
          Form(
            key: _formKey,
            child: annAsync.when(
              data: (all) {
                final anns1 = _annsForSlot(all, 1);
                final anns2 = _annsForSlot(all, 2);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _instructionField(
                      controller: _instruction1Controller,
                      label: 'Text for Image 1',
                      hint: 'e.g. Press the red power button',
                      requiredField: true,
                    ),
                    const SizedBox(height: 12),
                    _StepImageEditorTile(
                      title: 'Image 1',
                      image: _img1,
                      annotations: anns1,
                      onAddOrReplace: () => _pickOrCaptureForSlot(1),
                      onAdjust: () => _adjustExisting(1),
                      onHighlights:
                      (_img1 == null) ? null : () => _openHighlightEditor(1),
                    ),
                    if (_twoImages) ...[
                      const SizedBox(height: 18),
                      _instructionField(
                        controller: _instruction2Controller,
                        label: 'Text for Image 2',
                        hint: 'e.g. Then press the green start button',
                        requiredField: true,
                      ),
                      const SizedBox(height: 12),
                      _StepImageEditorTile(
                        title: 'Image 2',
                        image: _img2,
                        annotations: anns2,
                        onAddOrReplace: () => _pickOrCaptureForSlot(2),
                        onAdjust: () => _adjustExisting(2),
                        onHighlights: (_img2 == null)
                            ? null
                            : () => _openHighlightEditor(2),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _instructionField(
                      controller: _instruction1Controller,
                      label: 'Text for Image 1',
                      hint: 'e.g. Press the red power button',
                      requiredField: true,
                    ),
                    const SizedBox(height: 12),
                    _StepImageEditorTile(
                      title: 'Image 1',
                      image: _img1,
                      annotations: const [],
                      onAddOrReplace: () => _pickOrCaptureForSlot(1),
                      onAdjust: () => _adjustExisting(1),
                      onHighlights:
                      (_img1 == null) ? null : () => _openHighlightEditor(1),
                    ),
                    if (_twoImages) ...[
                      const SizedBox(height: 18),
                      _instructionField(
                        controller: _instruction2Controller,
                        label: 'Text for Image 2',
                        hint: 'e.g. Then press the green start button',
                        requiredField: true,
                      ),
                      const SizedBox(height: 12),
                      _StepImageEditorTile(
                        title: 'Image 2',
                        image: _img2,
                        annotations: const [],
                        onAddOrReplace: () => _pickOrCaptureForSlot(2),
                        onAdjust: () => _adjustExisting(2),
                        onHighlights: (_img2 == null)
                            ? null
                            : () => _openHighlightEditor(2),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          if (widget.stepId == null) ...[
            const SizedBox(height: 12),
            const Text(
              'Tip: Save the step first to enable highlights.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _instruction1Controller.dispose();
    _instruction2Controller.dispose();
    super.dispose();
  }
}

class _StepImageEditorTile extends StatelessWidget {
  final String title;
  final _StepImageRef? image;
  final List<StepAnnotation> annotations;
  final VoidCallback onAddOrReplace;
  final VoidCallback onAdjust;
  final VoidCallback? onHighlights;

  const _StepImageEditorTile({
    required this.title,
    required this.image,
    required this.annotations,
    required this.onAddOrReplace,
    required this.onAdjust,
    required this.onHighlights,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null && image!.path.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (!hasImage) {
              onAddOrReplace();
              return;
            }

            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (ctx) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_camera_back_outlined),
                        title: const Text('Replace image'),
                        onTap: () {
                          Navigator.pop(ctx);
                          onAddOrReplace();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.tune),
                        title: const Text('Adjust framing'),
                        onTap: () {
                          Navigator.pop(ctx);
                          onAdjust();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            );
          },
          child: _FramedImagePreview(
            image: image,
            annotations: annotations,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Highlights'),
          onPressed: onHighlights,
        ),
      ],
    );
  }
}

class _FramedImagePreview extends StatelessWidget {
  final _StepImageRef? image;
  final List<StepAnnotation> annotations;

  const _FramedImagePreview({
    required this.image,
    required this.annotations,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null && image!.path.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: _frameAspectRatio,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: hasImage
              ? Stack(
            fit: StackFit.expand,
            children: [
              _TransformedImageFill(
                file: image!.file,
                scale: image!.scale,
                tx: image!.tx,
                ty: image!.ty,
              ),
              if (annotations.isNotEmpty)
                HighlightOverlay(annotations: annotations),
            ],
          )
              : const _EmptyAddImageFrame(),
        ),
      ),
    );
  }
}

class _EmptyAddImageFrame extends StatelessWidget {
  const _EmptyAddImageFrame();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_circle_outline, size: 44, color: cs.primary),
          const SizedBox(height: 10),
          Text(
            'Add image',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransformedImageFill extends StatelessWidget {
  final File file;
  final double scale;
  final double tx;
  final double ty;

  const _TransformedImageFill({
    required this.file,
    required this.scale,
    required this.tx,
    required this.ty,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clampedScale = scale < 1.0 ? 1.0 : scale;
        final minT = 1.0 - clampedScale;
        final clampedTx = tx < minT ? minT : (tx > 0.0 ? 0.0 : tx);
        final clampedTy = ty < minT ? minT : (ty > 0.0 ? 0.0 : ty);
        final m = Matrix4.identity()
          ..translate(
            clampedTx * constraints.maxWidth,
            clampedTy * constraints.maxHeight,
          )
          ..scale(clampedScale, clampedScale);
        return ClipRect(
          child: Transform(
            transform: m,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
          ),
        );
      },
    );
  }
}

class _FrameAdjustScreen extends StatefulWidget {
  final _StepImageRef initial;

  const _FrameAdjustScreen({
    required this.initial,
  });

  @override
  State<_FrameAdjustScreen> createState() => _FrameAdjustScreenState();
}

class _FrameAdjustScreenState extends State<_FrameAdjustScreen> {
  static const double _maxUserScale = 6.0;

  late final TransformationController _controller;

  ui.Image? _decoded;
  Size _viewportSize = Size.zero;
  Rect _frameRect = Rect.zero;
  double _baseScale = 1.0;
  Size _childSize = Size.zero;

  bool _initializedTransform = false;
  bool _isClamping = false;
  bool _pendingInitTransform = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController(Matrix4.identity());
    _controller.addListener(_clampToFrame);
    _decode();
  }

  Future<void> _decode() async {
    final bytes = await widget.initial.file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _decoded = frame.image;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_clampToFrame);
    _controller.dispose();
    super.dispose();
  }

  void _reset() {
    _initializedTransform = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyInitialTransform();
    });
  }

  void _applyInitialTransform() {
    if (_viewportSize.isEmpty || _childSize.isEmpty) return;

    final dx = (_viewportSize.width - _childSize.width) / 2.0;
    final dy = (_viewportSize.height - _childSize.height) / 2.0;

    _controller.value = Matrix4.identity()..translate(dx, dy);

    _initializedTransform = true;
    _clampToFrame();
  }

  void _clampToFrame() {
    if (_isClamping) return;
    if (_viewportSize.isEmpty || _frameRect.isEmpty || _childSize.isEmpty) return;

    final m = Matrix4.fromList(_controller.value.storage);
    final currentScale = m.getMaxScaleOnAxis();
    final clampedScale = currentScale < 1.0
        ? 1.0
        : (currentScale > _maxUserScale ? _maxUserScale : currentScale);

    final childW = _childSize.width * clampedScale;
    final childH = _childSize.height * clampedScale;

    double tx = m.storage[12];
    double ty = m.storage[13];

    final minTx = _frameRect.right - childW;
    final maxTx = _frameRect.left;
    final minTy = _frameRect.bottom - childH;
    final maxTy = _frameRect.top;

    double newTx = tx;
    double newTy = ty;

    if (newTx < minTx) newTx = minTx;
    if (newTx > maxTx) newTx = maxTx;
    if (newTy < minTy) newTy = minTy;
    if (newTy > maxTy) newTy = maxTy;

    final changed =
        (clampedScale != currentScale) || (newTx != tx) || (newTy != ty);

    if (!changed) return;

    _isClamping = true;
    _controller.value = Matrix4.identity()
      ..translate(newTx, newTy)
      ..scale(clampedScale);
    _isClamping = false;
  }

  Future<void> _save() async {
    _clampToFrame();

    final img = _decoded;
    if (img == null) return;
    if (_viewportSize.isEmpty || _frameRect.isEmpty || _childSize.isEmpty) return;

    final inv = Matrix4.inverted(_controller.value);

    Offset childTL = MatrixUtils.transformPoint(inv, _frameRect.topLeft);
    Offset childBR = MatrixUtils.transformPoint(inv, _frameRect.bottomRight);

    Rect src = Rect.fromPoints(
      Offset(childTL.dx / _baseScale, childTL.dy / _baseScale),
      Offset(childBR.dx / _baseScale, childBR.dy / _baseScale),
    );

    final imgW = img.width.toDouble();
    final imgH = img.height.toDouble();

    double left = src.left.clamp(0.0, imgW);
    double top = src.top.clamp(0.0, imgH);
    double right = src.right.clamp(0.0, imgW);
    double bottom = src.bottom.clamp(0.0, imgH);

    final size = math.min(right - left, bottom - top);
    right = left + size;
    bottom = top + size;

    if (size <= 1) return;

    const outSize = 1024;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dst = Rect.fromLTWH(0, 0, outSize.toDouble(), outSize.toDouble());

    final srcRect = Rect.fromLTWH(left, top, size, size);
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(img, srcRect, dst, paint);

    final picture = recorder.endRecording();
    final outImage = await picture.toImage(outSize, outSize);
    final bytes = await outImage.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;

    final dir = widget.initial.file.parent;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outFile = File('${dir.path}/step_${ts}_square.png');
    await outFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

    if (!mounted) return;

    Navigator.of(context).pop(
      _StepImageRef(
        path: outFile.path,
        scale: 1.0,
        tx: 0.0,
        ty: 0.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = _decoded;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Adjust image'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Pinch to zoom and drag to position the image\ninside the frame.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: AspectRatio(
                      aspectRatio: 0.80,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final vw = constraints.maxWidth;
                          final vh = constraints.maxHeight;

                          _viewportSize = Size(vw, vh);

                          final frameSide = math.min(vw, vh) * 0.84;
                          final frameLeft = (vw - frameSide) / 2.0;
                          final frameTop = (vh - frameSide) / 2.0;
                          _frameRect = Rect.fromLTWH(
                            frameLeft,
                            frameTop,
                            frameSide,
                            frameSide,
                          );

                          if (img != null) {
                            final imgW = img.width.toDouble();
                            final imgH = img.height.toDouble();
                            final baseScale =
                            math.max(frameSide / imgW, frameSide / imgH);

                            _baseScale = baseScale;
                            _childSize = Size(imgW * baseScale, imgH * baseScale);

                            if (!_initializedTransform && !_pendingInitTransform) {
                              _pendingInitTransform = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _pendingInitTransform = false;
                                _applyInitialTransform();
                              });
                            }
                          } else {
                            _childSize = const Size(1, 1);
                          }

                          return ClipRect(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (img == null)
                                  const Center(child: CircularProgressIndicator())
                                else
                                  InteractiveViewer(
                                    transformationController: _controller,
                                    minScale: 0.5,
                                    maxScale: _maxUserScale,
                                    boundaryMargin:
                                    const EdgeInsets.all(double.infinity),
                                    constrained: false,
                                    onInteractionEnd: (_) => _clampToFrame(),
                                    child: SizedBox(
                                      width: _childSize.width,
                                      height: _childSize.height,
                                      child: RawImage(
                                        image: img,
                                        fit: BoxFit.fill,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                IgnorePointer(
                                  child: CustomPaint(
                                    painter: _SquareHoleScrimPainter(
                                      holeRect: _frameRect,
                                      color: Colors.white,
                                      opacity: 1.0,
                                      radius: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        onPressed: _reset,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Use framing'),
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareHoleScrimPainter extends CustomPainter {
  final Rect holeRect;
  final Color color;
  final double opacity;
  final double radius;

  const _SquareHoleScrimPainter({
    required this.holeRect,
    required this.color,
    required this.opacity,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(opacity);

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, paint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    final rrect = RRect.fromRectAndRadius(holeRect, Radius.circular(radius));
    canvas.drawRRect(rrect, clearPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SquareHoleScrimPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.radius != radius;
  }
}
