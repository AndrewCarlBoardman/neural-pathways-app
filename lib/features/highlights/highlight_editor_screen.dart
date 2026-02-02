import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../shared/db/app_db.dart';

class HighlightEditorScreen extends StatefulWidget {
  final int stepId;
  final ImageProvider imageProvider;
  final StepHighlight? existing;

  /// Saves a rectangle highlight in relative (0..1) coords.
  final Future<void> Function({
  required double x,
  required double y,
  required double w,
  required double h,
  }) onSave;

  final Future<void> Function() onDelete;

  const HighlightEditorScreen({
    super.key,
    required this.stepId,
    required this.imageProvider,
    required this.existing,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<HighlightEditorScreen> createState() => _HighlightEditorScreenState();
}

class _HighlightEditorScreenState extends State<HighlightEditorScreen> {
  final TransformationController _tx = TransformationController();

  // Intrinsic image size (pixels) — ONLY used to compute aspect ratio.
  Size? _imagePxSize;

  // Scene size (logical pixels) — used for ALL coordinate math.
  Size? _sceneSize;

  Rect? _relRect; // 0..1
  Offset? _dragStartScene;

  bool _isDrawing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _relRect = widget.existing == null
        ? null
        : Rect.fromLTWH(
      widget.existing!.x,
      widget.existing!.y,
      widget.existing!.w,
      widget.existing!.h,
    );
    _resolveImagePxSize(widget.imageProvider);
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
      Navigator.pop(context);
    });

    stream.addListener(listener);
  }

  /// Convert a point from GestureDetector local coords into "scene" coords by inverting the transform.
  Offset _toScene(Offset local) {
    final inv = Matrix4.inverted(_tx.value);
    final v = inv.transform3(Vector3(local.dx, local.dy, 0));
    return Offset(v.x, v.y);
  }

  Rect _rectFromTwoPoints(Offset a, Offset b) {
    final left = math.min(a.dx, b.dx);
    final top = math.min(a.dy, b.dy);
    final right = math.max(a.dx, b.dx);
    final bottom = math.max(a.dy, b.dy);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect _sceneRectToRel(Rect sceneRect) {
    final s = _sceneSize!;
    double rx(double v) => (v / s.width).clamp(0.0, 1.0);
    double ry(double v) => (v / s.height).clamp(0.0, 1.0);
    return Rect.fromLTRB(
      rx(sceneRect.left),
      ry(sceneRect.top),
      rx(sceneRect.right),
      ry(sceneRect.bottom),
    );
  }

  Rect _relRectToScene(Rect relRect) {
    final s = _sceneSize!;
    return Rect.fromLTWH(
      relRect.left * s.width,
      relRect.top * s.height,
      relRect.width * s.width,
      relRect.height * s.height,
    );
  }

  Future<void> _save() async {
    if (_relRect == null) return;
    setState(() => _saving = true);
    try {
      final r = _relRect!;
      await widget.onSave(x: r.left, y: r.top, w: r.width, h: r.height);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await widget.onDelete();
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final px = _imagePxSize;
    if (px == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Highlight'),
        actions: [
          if (widget.existing != null)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove highlight',
            ),
          TextButton(
            onPressed: (_saving || _relRect == null) ? null : _save,
            child: _saving
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Save'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Compute a LOGICAL scene size that fits the screen while keeping image aspect ratio.
          final aspect = px.width / px.height;
          double sceneW = constraints.maxWidth;
          double sceneH = sceneW / aspect;

          if (sceneH > constraints.maxHeight) {
            sceneH = constraints.maxHeight;
            sceneW = sceneH * aspect;
          }

          _sceneSize = Size(sceneW, sceneH);

          return Center(
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _tx,
                minScale: 1,
                maxScale: 6,

                // ✅ Phase 1 polish: disable pan/zoom while drawing.
                panEnabled: !_isDrawing,
                scaleEnabled: !_isDrawing,

                child: SizedBox(
                  width: sceneW,
                  height: sceneH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(image: widget.imageProvider, fit: BoxFit.fill),

                      // Draw current rect (in scene coords)
                      if (_relRect != null)
                        CustomPaint(
                          painter: _HighlightRectPainter(
                            sceneRect: _relRectToScene(_relRect!),
                          ),
                        ),

                      // Drag to draw
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanStart: (d) {
                            final scene = _toScene(d.localPosition);
                            setState(() {
                              _isDrawing = true;
                              _dragStartScene = scene;
                              _relRect = _sceneRectToRel(
                                Rect.fromCenter(center: scene, width: 1, height: 1),
                              );
                            });
                          },
                          onPanUpdate: (d) {
                            if (_dragStartScene == null) return;
                            final scene = _toScene(d.localPosition);
                            setState(() {
                              _relRect = _sceneRectToRel(
                                _rectFromTwoPoints(_dragStartScene!, scene),
                              );
                            });
                          },
                          onPanEnd: (_) {
                            setState(() {
                              _dragStartScene = null;
                              _isDrawing = false;
                            });
                          },
                          onPanCancel: () {
                            setState(() {
                              _dragStartScene = null;
                              _isDrawing = false;
                            });
                          },
                        ),
                      ),

                      // Bottom hint above system nav
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: SafeArea(
                          top: false,
                          left: false,
                          right: false,
                          bottom: true,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Pinch to zoom. Drag to draw the highlight rectangle.',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HighlightRectPainter extends CustomPainter {
  final Rect sceneRect;
  _HighlightRectPainter({required this.sceneRect});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.yellow.withOpacity(0.20);
    final stroke = Paint()
      ..color = Colors.yellow.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRect(sceneRect, fill);
    canvas.drawRect(sceneRect, stroke);
  }

  @override
  bool shouldRepaint(covariant _HighlightRectPainter oldDelegate) {
    return oldDelegate.sceneRect != sceneRect;
  }
}
