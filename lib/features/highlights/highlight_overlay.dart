import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/db/app_db.dart';

class HighlightOverlay extends StatelessWidget {
  final List<StepAnnotation> annotations;

  const HighlightOverlay({
    super.key,
    required this.annotations,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final square = _squareBounds(size);

          return Stack(
            children: [
              for (final a in annotations)
                if (a.kind == 0 && (a.shapeType ?? 0) == 2)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ArrowPainter(
                        annotation: a,
                        square: square,
                      ),
                    ),
                  )
                else
                  _OverlayItem(
                    annotation: a,
                    square: square,
                  ),
            ],
          );
        },
      ),
    );
  }

  static Rect _squareBounds(Size size) {
    final side = math.min(size.width, size.height);
    final left = (size.width - side) / 2;
    final top = (size.height - side) / 2;
    return Rect.fromLTWH(left, top, side, side);
  }
}

class _OverlayItem extends StatelessWidget {
  final StepAnnotation annotation;
  final Rect square;

  const _OverlayItem({
    required this.annotation,
    required this.square,
  });

  Color _paletteColor(int idx) {
    switch (idx.clamp(0, 4)) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.white;
      case 4:
        return Colors.black;
      default:
        return Colors.yellow;
    }
  }

  ({int border, int fill}) _unpackShapeColor(int packed) {
    if (packed >= 0 && packed <= 4) {
      return (border: packed, fill: packed);
    }
    final border = packed % 10;
    final fill = (packed ~/ 10) % 10;
    return (
    border: border.clamp(0, 4),
    fill: fill.clamp(0, 4),
    );
  }

  ({int border, int bg, int text, int size}) _unpackTextColor(int packed) {
    final border = packed % 10;
    final bg = (packed ~/ 10) % 10;
    final text = (packed ~/ 100) % 10;
    final size = (packed ~/ 1000) % 10;
    return (
    border: border.clamp(0, 4),
    bg: bg.clamp(0, 4),
    text: text.clamp(0, 4),
    size: size.clamp(0, 2),
    );
  }

  double _fontSizeForPacked(int size) {
    switch (size) {
      case 2:
        return 26.0;
      case 1:
        return 20.0;
      default:
        return 15.0;
    }
  }

  Rect _normRectToSquare(Rect square, StepAnnotation a) {
    return Rect.fromLTWH(
      square.left + (a.x * square.width),
      square.top + (a.y * square.height),
      a.w * square.width,
      a.h * square.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rect = _normRectToSquare(square, annotation);

    if (annotation.kind == 0) {
      final colors = _unpackShapeColor(annotation.color);
      final borderColor = _paletteColor(colors.border).withOpacity(0.95);
      final fillColor = _paletteColor(colors.fill).withOpacity(0.18);
      final isCircle = (annotation.shapeType ?? 0) == 1;

      return Positioned.fromRect(
        rect: rect,
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(
              color: borderColor,
              width: 3,
            ),
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(10),
          ),
        ),
      );
    }

    final label = (annotation.label ?? '').trim();
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = _unpackTextColor(annotation.color);
    final borderColor = _paletteColor(colors.border).withOpacity(0.95);
    final bgColor = _paletteColor(colors.bg).withOpacity(0.60);
    final textColor = _paletteColor(colors.text);
    final fontSize = _fontSizeForPacked(colors.size);

    return Positioned.fromRect(
      rect: rect,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final StepAnnotation annotation;
  final Rect square;

  const _ArrowPainter({
    required this.annotation,
    required this.square,
  });

  Color _paletteColor(int idx) {
    switch (idx.clamp(0, 4)) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.white;
      case 4:
        return Colors.black;
      default:
        return Colors.yellow;
    }
  }

  Offset _normPointToSquare(double x, double y) {
    return Offset(
      square.left + (x * square.width),
      square.top + (y * square.height),
    );
  }

  double _arrowStroke(double side) => (side * 0.0080).clamp(2.2, 3.2);
  double _arrowHead(double side) => (side * 0.040).clamp(10.0, 16.0);

  @override
  void paint(Canvas canvas, Size size) {
    final tip = _normPointToSquare(annotation.x, annotation.y);
    final tail = _normPointToSquare(
      annotation.x + annotation.w,
      annotation.y + annotation.h,
    );

    final paint = Paint()
      ..color = _paletteColor(annotation.color).withOpacity(0.95)
      ..strokeWidth = _arrowStroke(square.width)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawLine(tail, tip, paint);

    final dir = tip - tail;
    final len = dir.distance;
    if (len <= 0.01) return;

    final u = dir / len;
    final headLen = _arrowHead(square.width);
    const headAngle = 0.55;

    Offset rot(Offset v, double a) {
      return Offset(
        v.dx * math.cos(a) - v.dy * math.sin(a),
        v.dx * math.sin(a) + v.dy * math.cos(a),
      );
    }

    final left = rot(u, headAngle);
    final right = rot(u, -headAngle);

    canvas.drawLine(tip, tip - left * headLen, paint);
    canvas.drawLine(tip, tip - right * headLen, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.annotation != annotation || oldDelegate.square != square;
  }
}
