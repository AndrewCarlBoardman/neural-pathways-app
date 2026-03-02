import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';
import '../../highlights/highlight_overlay.dart';

const int _slot2SortOrderBase = 1000;
const double _frameAspectRatio = 1.0;

final stepsForViewerProvider =
StreamProvider.family<List<Step>, int>((ref, guideId) {
  final db = ref.watch(dbProvider);
  return db.watchStepsForGuide(guideId);
});

final annotationsForStepProvider =
StreamProvider.family<List<StepAnnotation>, int>((ref, stepId) {
  final db = ref.watch(dbProvider);
  return db.watchAnnotationsForStep(stepId);
});

/// Same encoding used by StepCreateScreen.
class _StepImagesPayload {
  final _StepImageRef? a;
  final _StepImageRef? b;

  const _StepImagesPayload({required this.a, required this.b});

  bool get hasTwo => b != null;

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
}

class StepViewerScreen extends ConsumerStatefulWidget {
  final int guideId;
  const StepViewerScreen({super.key, required this.guideId});

  @override
  ConsumerState<StepViewerScreen> createState() => _StepViewerScreenState();
}

class _StepViewerScreenState extends ConsumerState<StepViewerScreen> {
  int index = 0;

  void _next(List<Step> steps) {
    if (index < steps.length - 1) setState(() => index++);
  }

  void _back() {
    if (index > 0) setState(() => index--);
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

  @override
  Widget build(BuildContext context) {
    final stepsAsync = ref.watch(stepsForViewerProvider(widget.guideId));

    return Scaffold(
      appBar: AppBar(title: const Text('User View')),
      body: stepsAsync.when(
        data: (steps) {
          if (steps.isEmpty) return const Center(child: Text('No steps yet.'));

          if (index >= steps.length) index = steps.length - 1;
          final step = steps[index];

          final annAsync = ref.watch(annotationsForStepProvider(step.id));
          final payload = _StepImagesPayload.fromPhotoPath(step.photoPath);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Step ${step.stepIndex} of ${steps.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    annAsync.when(
                      data: (all) {
                        final a1 = _annsForSlot(all, 1);
                        final a2 = _annsForSlot(all, 2);
                        return _StepImagesViewer(
                          img1: payload.a,
                          img2: payload.b,
                          anns1: a1,
                          anns2: a2,
                        );
                      },
                      loading: () => _StepImagesViewer(
                        img1: payload.a,
                        img2: payload.b,
                        anns1: const [],
                        anns2: const [],
                      ),
                      error: (_, __) => _StepImagesViewer(
                        img1: payload.a,
                        img2: payload.b,
                        anns1: const [],
                        anns2: const [],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      step.instructionText,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: index == 0 ? null : _back,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Back', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: index == steps.length - 1
                              ? null
                              : () => _next(steps),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Next', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StepImagesViewer extends StatelessWidget {
  final _StepImageRef? img1;
  final _StepImageRef? img2;
  final List<StepAnnotation> anns1;
  final List<StepAnnotation> anns2;

  const _StepImagesViewer({
    required this.img1,
    required this.img2,
    required this.anns1,
    required this.anns2,
  });

  @override
  Widget build(BuildContext context) {
    final has1 = img1 != null && img1!.path.trim().isNotEmpty;
    final has2 = img2 != null && img2!.path.trim().isNotEmpty;

    if (!has1 && !has2) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _frameAspectRatio,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: const Text('No image'),
            ),
          ),
      );
      }

          if (!has2) {
        return _FramedImageWithOverlay(img: img1!, annotations: anns1);
      }

      return Row(
        children: [
          Expanded(child: _FramedImageWithOverlay(img: img1, annotations: anns1)),
          const SizedBox(width: 12),
          Expanded(child: _FramedImageWithOverlay(img: img2, annotations: anns2)),
        ],
      );
    }
}

class _FramedImageWithOverlay extends StatelessWidget {
  final _StepImageRef? img;
  final List<StepAnnotation> annotations;

  const _FramedImageWithOverlay({required this.img, required this.annotations});

  @override
  Widget build(BuildContext context) {
    if (img == null || img!.path.trim().isEmpty) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _frameAspectRatio,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: const Text('No image'),
            ),
          ),
      );
          }

          return ClipRRect(
          borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
    aspectRatio: _frameAspectRatio,
    child: Container(
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: Stack(
    fit: StackFit.expand,
    children: [
    _TransformedImageFill(
    file: img!.file,
    scale: img!.scale,
    tx: img!.tx,
    ty: img!.ty,
    ),
    if (annotations.isNotEmpty) HighlightOverlay(annotations: annotations),
    ],
    ),
    ),
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
        final m = Matrix4.identity()
          ..translate(tx * constraints.maxWidth, ty * constraints.maxHeight)
          ..scale(scale, scale);
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
