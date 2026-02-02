import 'dart:io';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/db/app_db.dart';
import '../../../shared/db/db_provider.dart';
import '../../highlights/highlight_overlay.dart';

final stepsForViewerProvider = StreamProvider.family<List<Step>, int>((ref, guideId) {
  final db = ref.watch(dbProvider);
  return db.watchStepsForGuide(guideId);
});

final highlightForStepProvider = StreamProvider.family<StepHighlight?, int>((ref, stepId) {
  final db = ref.watch(dbProvider);
  return db.watchHighlightForStep(stepId);
});

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
          final highlightAsync = ref.watch(highlightForStepProvider(step.id));

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Step ${step.stepIndex} of ${steps.length}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: (step.photoPath != null && step.photoPath!.isNotEmpty)
                          ? highlightAsync.when(
                        data: (h) => _StepPhotoWithHighlight(
                          photoPath: step.photoPath!,
                          highlight: h,
                        ),
                        loading: () => _StepPhotoWithHighlight(
                          photoPath: step.photoPath!,
                          highlight: null,
                        ),
                        error: (_, __) => _StepPhotoWithHighlight(
                          photoPath: step.photoPath!,
                          highlight: null,
                        ),
                      )
                          : Container(
                        height: 240,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(),
                        ),
                        child: const Text('No image'),
                      ),
                    ),

                    const SizedBox(height: 18),
                    Text(
                      step.instructionText,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
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
                          onPressed: index == steps.length - 1 ? null : () => _next(steps),
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

/// Displays the FULL image (no crop) using AspectRatio so the highlight overlay
/// lines up perfectly with the saved 0..1 coordinates.
class _StepPhotoWithHighlight extends StatefulWidget {
  final String photoPath;
  final StepHighlight? highlight;

  const _StepPhotoWithHighlight({
    required this.photoPath,
    required this.highlight,
  });

  @override
  State<_StepPhotoWithHighlight> createState() => _StepPhotoWithHighlightState();
}

class _StepPhotoWithHighlightState extends State<_StepPhotoWithHighlight> {
  double? _aspect;

  @override
  void initState() {
    super.initState();
    _resolveAspect();
  }

  @override
  void didUpdateWidget(covariant _StepPhotoWithHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath) {
      _aspect = null;
      _resolveAspect();
    }
  }

  void _resolveAspect() {
    final provider = FileImage(File(widget.photoPath));
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;

    listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() {
        _aspect = info.image.width / info.image.height;
      });
      stream.removeListener(listener);
    }, onError: (e, st) {
      stream.removeListener(listener);
      if (!mounted) return;
      // Fallback so the UI doesn't get stuck if the image fails to decode.
      setState(() => _aspect = 16 / 9);
    });

    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspect;
    if (aspect == null) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 240,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(widget.photoPath),
                fit: BoxFit.fill, // IMPORTANT: no crop, matches overlay coords
              ),
              if (widget.highlight != null)
                HighlightOverlay(highlight: widget.highlight!),
            ],
          ),
        ),
      ),
    );
  }
}
