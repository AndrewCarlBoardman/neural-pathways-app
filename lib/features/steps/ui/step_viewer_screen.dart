import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    if (index < steps.length - 1) {
      setState(() => index++);
    }
  }

  void _back() {
    if (index > 0) {
      setState(() => index--);
    }
  }

  Future<void> _leaveUserView() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit guide mode?'),
        content: const Text('Return to the main Caregiver Guides screen.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay in guide'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      context.go('/receiver');
    }
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide View'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'exit') {
                _leaveUserView();
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
      body: stepsAsync.when(
        data: (steps) {
          if (steps.isEmpty) {
            return const Center(child: Text('No steps yet.'));
          }

          if (index >= steps.length) {
            index = steps.length - 1;
          }
          final step = steps[index];
          final annAsync = ref.watch(annotationsForStepProvider(step.id));
          final payload = _StepImagesPayload.fromPhotoPath(step.photoPath);
          final progress = (index + 1) / steps.length;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step ${index + 1} of ${steps.length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    annAsync.when(
                      data: (all) {
                        final a1 = _annsForSlot(all, 1);
                        final a2 = _annsForSlot(all, 2);

                        return _StepContentViewer(
                          text1: step.instructionText,
                          text2: step.instructionText2,
                          img1: payload.a,
                          img2: payload.b,
                          anns1: a1,
                          anns2: a2,
                        );
                      },
                      loading: () => _StepContentViewer(
                        text1: step.instructionText,
                        text2: step.instructionText2,
                        img1: payload.a,
                        img2: payload.b,
                        anns1: const [],
                        anns2: const [],
                      ),
                      error: (_, __) => _StepContentViewer(
                        text1: step.instructionText,
                        text2: step.instructionText2,
                        img1: payload.a,
                        img2: payload.b,
                        anns1: const [],
                        anns2: const [],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        offset: Offset(0, -2),
                        color: Color(0x12000000),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: index == 0 ? null : _back,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Back', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: index == steps.length - 1
                              ? null
                              : () => _next(steps),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              index == steps.length - 1 ? 'Finished' : 'Next',
                              style: const TextStyle(fontSize: 20),
                            ),
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

class _StepContentViewer extends StatelessWidget {
  final String text1;
  final String? text2;
  final _StepImageRef? img1;
  final _StepImageRef? img2;
  final List<StepAnnotation> anns1;
  final List<StepAnnotation> anns2;

  const _StepContentViewer({
    required this.text1,
    required this.text2,
    required this.img1,
    required this.img2,
    required this.anns1,
    required this.anns2,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];

    blocks.add(
      _InstructionCard(
        text: text1,
        img: img1,
        annotations: anns1,
      ),
    );

    final secondText = (text2 ?? '').trim();
    final hasSecondImage = img2 != null && img2!.path.trim().isNotEmpty;

    if (secondText.isNotEmpty || hasSecondImage) {
      blocks.add(const SizedBox(height: 18));
      blocks.add(
        _InstructionCard(
          text: secondText,
          img: img2,
          annotations: anns2,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String text;
  final _StepImageRef? img;
  final List<StepAnnotation> annotations;

  const _InstructionCard({
    required this.text,
    required this.img,
    required this.annotations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (text.trim().isNotEmpty) ...[
            Text(
              text,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 14),
          ],
          _FramedImageWithOverlay(img: img, annotations: annotations),
        ],
      ),
    );
  }
}

class _FramedImageWithOverlay extends StatelessWidget {
  final _StepImageRef? img;
  final List<StepAnnotation> annotations;

  const _FramedImageWithOverlay({
    required this.img,
    required this.annotations,
  });

  @override
  Widget build(BuildContext context) {
    if (img == null || img!.path.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: _frameAspectRatio,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: const Text('No image'),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: _frameAspectRatio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
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
              if (annotations.isNotEmpty)
                HighlightOverlay(annotations: annotations),
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
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final matrix = Matrix4.identity()
          ..translate(tx * width, ty * height)
          ..scale(scale);

        return ClipRect(
          child: Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: SizedBox(
              width: width,
              height: height,
              child: Image.file(
                file,
                fit: BoxFit.fill,
                width: width,
                height: height,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('Unable to load image'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
